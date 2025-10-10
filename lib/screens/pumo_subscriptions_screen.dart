import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../theme/pumo_theme.dart';

class PumoPremiumScreen extends StatefulWidget {
  final int initialPlanIndex;
  const PumoPremiumScreen({super.key, this.initialPlanIndex = 0});

  @override
  State<PumoPremiumScreen> createState() => _PumoPremiumScreenState();
}

class _PumoPremiumScreenState extends State<PumoPremiumScreen> with TickerProviderStateMixin {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isLoading = false; // 改为false，不在初始化时加载
  bool _purchasePending = false;
  int _selectedPlanIndex = 0;
  bool _isPremiumActive = false;
  DateTime? _premiumExpiry;
  DateTime? _lastSnackBarTime;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _productsLoaded = false; // 新增：标记商品是否已加载

  // Pumo Premium 订阅套餐配置
  final List<_PumoPremiumPlan> _premiumPlans = [
    _PumoPremiumPlan(
      title: '12.99',
      subTitle: 'Per week',
      total: 'Total \$12.99',
      desc: '+7 Days Premium',
      productId: 'PumoWeekVIP',
      popular: false,
    ),
    _PumoPremiumPlan(
      title: '49.99',
      subTitle: 'Per month',
      total: 'Total \$49.99',
      desc: '+30 Days Premium',
      productId: 'PumoMonthVIP',
      popular: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlanIndex = widget.initialPlanIndex;
    
    // 初始化动画控制器
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
    
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(_listenToPurchaseUpdated, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint("Error in IAP Stream: $error");
    });
    // 移除自动初始化内购，改为延迟加载
    _loadPremiumStatus();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // 新增：延迟加载商品信息，只在用户需要购买时才加载
  Future<void> _loadProductsIfNeeded() async {
    if (_productsLoaded) {
      return; // 如果已经加载过，直接返回
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Store not available");
      return;
    }
    
    final Set<String> productIds = _premiumPlans.map((e) => e.productId).toSet();
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      setState(() {
        _products = response.productDetails;
        _isLoading = false;
        _productsLoaded = true; // 标记为已加载
      });
      
      if (response.productDetails.isEmpty) {
        _showSnackBar("No subscription products available");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Failed to load subscription products: $e");
    }
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremiumActive = prefs.getBool('isVip') ?? false;
      final expiryStr = prefs.getString('vipExpiry');
      _premiumExpiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint('Purchase status: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _purchasePending = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _purchasePending = false;
          });
          _showSnackBar("Purchase failed: ${purchaseDetails.error?.message ?? 'Unknown error'}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('Successful purchase/restore: ${purchaseDetails.productID}');
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          setState(() {
            _purchasePending = false;
          });
          _showSnackBar("Purchase was canceled");
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    setState(() {
      _purchasePending = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVip', true);
    // 计算有效期和Premium类型
    DateTime now = DateTime.now();
    DateTime expiry;
    String premiumType;
    if (purchaseDetails.productID == 'PumoWeekVIP') {
      expiry = now.add(const Duration(days: 7));
      premiumType = 'weekly';
    } else if (purchaseDetails.productID == 'PumoMonthVIP') {
      expiry = now.add(const Duration(days: 30));
      premiumType = 'monthly';
    } else {
      expiry = now;
      premiumType = 'unknown';
    }
    await prefs.setString('vipExpiry', expiry.toIso8601String());
    await prefs.setString('vip_type', premiumType);
          _showSnackBar("Pumo Premium activated!");
    await _loadPremiumStatus();
  }

  void _showSnackBar(String msg) {
    final now = DateTime.now();
    if (_lastSnackBarTime != null && now.difference(_lastSnackBarTime!).inSeconds < 3) {
      return;
    }
    _lastSnackBarTime = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: PumoTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _processPurchase() async {
    // 在购买前确保商品已加载
    if (!_productsLoaded) {
      await _loadProductsIfNeeded();
    }
    
    final plan = _premiumPlans[_selectedPlanIndex];
    final ProductDetails? product = _products.firstWhereOrNull((p) => p.id == plan.productId);
    if (product == null) {
      _showSnackBar("Product not available");
      return;
    }
    setState(() {
      _purchasePending = true;
    });
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      setState(() {
        _purchasePending = false;
      });
      _showSnackBar("Error starting purchase: $e");
    }
  }

  Future<void> _restorePurchases() async {
    // 在恢复前确保商品已加载
    if (!_productsLoaded) {
      await _loadProductsIfNeeded();
    }
    
    setState(() {
      _purchasePending = true;
    });
    
    try {
      debugPrint('Starting restore purchases...');
      await _inAppPurchase.restorePurchases();
      _showSnackBar("Restoring purchases... Please wait.");
      
      // 给一些时间让恢复过程完成
      await Future.delayed(const Duration(seconds: 2));
      
      // 重新加载Premium状态以检查是否有恢复的购买
      await _loadPremiumStatus();
      
      if (_isPremiumActive) {
        _showSnackBar("Purchases restored successfully! Pumo Premium activated.");
      } else {
        _showSnackBar("No previous purchases found to restore.");
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _showSnackBar("Error restoring purchases: $e");
    } finally {
      setState(() {
        _purchasePending = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // Define privileges for each plan
    final List<List<_Privilege>> planPrivileges = [
      // Weekly
      [
        _Privilege(icon: Icons.auto_awesome, text: 'Unlimited access to others profiles'),
        _Privilege(icon: Icons.face_retouching_natural, text: 'Unlimited modification of the avatar'),
        _Privilege(icon: Icons.block, text: 'Ad-free experience'),
      ],
      // Monthly
      [
        _Privilege(icon: Icons.auto_awesome, text: 'Unlimited access to others profiles'),
        _Privilege(icon: Icons.face_retouching_natural, text: 'Unlimited modification of the avatar'),
        _Privilege(icon: Icons.block, text: 'Ad-free experience'),
        _Privilege(icon: Icons.rocket_launch, text: 'Create AI characters infinitely'),
      ],
    ];
    final privileges = planPrivileges[_selectedPlanIndex];
    
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PumoTheme.primaryColor,
              PumoTheme.secondaryColor,
              PumoTheme.accentColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Custom App Bar
                  SliverAppBar(
                    expandedHeight: _isPremiumActive && _premiumExpiry != null ? 400 : 320,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [PumoTheme.secondaryColor, PumoTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PumoTheme.secondaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              
                              // 装饰性顶部条
                              Container(
                                width: 80,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, PumoTheme.accentColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                            
                            // Premium Status Card (if active)
                            if (_isPremiumActive && _premiumExpiry != null) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      PumoTheme.accentColor.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: PumoTheme.accentColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: PumoTheme.primaryColor.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pumo Premium Active',
                                            style: TextStyle(
                                              color: PumoTheme.secondaryColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Expires: ${_premiumExpiry!.year}-${_premiumExpiry!.month.toString().padLeft(2, '0')}-${_premiumExpiry!.day.toString().padLeft(2, '0')} (${_premiumExpiry!.difference(DateTime.now()).inDays} days)',
                                            style: const TextStyle(
                                              color: PumoTheme.primaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Premium图标
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.white, PumoTheme.accentColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: PumoTheme.accentColor.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        ),
                                        Positioned(
                                          top: 15,
                                          right: 15,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [PumoTheme.accentColor, PumoTheme.secondaryColor],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                           
                            
                          ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subscription Plans
                          Row(
                            children: List.generate(_premiumPlans.length, (i) {
                              final plan = _premiumPlans[i];
                              final selected = i == _selectedPlanIndex;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPlanIndex = i;
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: i == 0 ? 12 : 0, left: i == 1 ? 12 : 0),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: selected 
                                          ? LinearGradient(
                                              colors: [PumoTheme.secondaryColor, PumoTheme.accentColor],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.9),
                                                PumoTheme.accentColor.withOpacity(0.1),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: selected 
                                            ? Colors.white.withOpacity(0.3)
                                            : PumoTheme.secondaryColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selected 
                                              ? PumoTheme.secondaryColor.withOpacity(0.4)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: selected ? 15 : 10,
                                          offset: Offset(0, selected ? 6 : 3),
                                        ),
                                        if (selected)
                                          BoxShadow(
                                            color: PumoTheme.accentColor.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 0),
                                          ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '\$${plan.title}',
                                          style: TextStyle(
                                            color: selected ? Colors.white : PumoTheme.secondaryColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 26,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          plan.subTitle,
                                          style: TextStyle(
                                            color: selected 
                                                ? Colors.white.withOpacity(0.9) 
                                                : PumoTheme.primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: selected 
                                                ? Colors.white.withOpacity(0.2)
                                                : PumoTheme.secondaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: selected 
                                                  ? Colors.white.withOpacity(0.3)
                                                  : PumoTheme.secondaryColor.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            plan.desc,
                                            style: TextStyle(
                                              color: selected ? Colors.white : PumoTheme.secondaryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Features Title
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  PumoTheme.accentColor.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Pumo Premium Benefits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PumoTheme.secondaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Features List
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  PumoTheme.accentColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFf093fb).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                for (int i = 0; i < privileges.length; i++) ...[
                                  _PumoPremiumPrivilegeItem(
                                    icon: privileges[i].icon,
                                    text: privileges[i].text,
                                  ),
                                  if (i != privileges.length - 1) 
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Container(
                                        height: 1,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              PumoTheme.secondaryColor.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        
                          const SizedBox(height: 32),
                          
                          // Purchase Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: GestureDetector(
                              onTap: _purchasePending ? null : _processPurchase,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [PumoTheme.secondaryColor, PumoTheme.accentColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PumoTheme.secondaryColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: PumoTheme.accentColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: _purchasePending
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        'Start Pumo Premium',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Restore Purchases Button
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    PumoTheme.accentColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: _purchasePending ? null : _restorePurchases,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.restore,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Restore Purchases',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                          const SizedBox(height: 32),
                          
                          // Legal Links
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  PumoTheme.accentColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => _launchURL('https://www.privacypolicies.com/live/1f488a81-e014-4cea-a08d-5e295a51f16d'),
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                TextButton(
                                  onPressed: () => _launchURL('https://www.apple.com/legal/internet-services/itunes/dev/stdeula'),
                                  child: Text(
                                    'Terms of Use',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Subscription Terms
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  PumoTheme.accentColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFf093fb).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pumo Premium Terms',
                                  style: TextStyle(
                                    color: PumoTheme.secondaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '• Weekly subscription: \$12.99 per week\n'
                                  '• Monthly subscription: \$49.99 per month\n\n'
                                  'Payment will be charged to your Apple ID account at the confirmation of purchase. Your subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.\n\n'
                                  'To cancel your subscription:\n'
                                  '1. Open the Settings app\n'
                                  '2. Tap your Apple ID at the top\n'
                                  '3. Tap Subscriptions\n'
                                  '4. Find Pumo Premium in the list\n'
                                  '5. Tap Cancel Subscription',
                                  style: TextStyle(
                                    color: PumoTheme.primaryColor,
                                    fontSize: 13,
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PumoPremiumPlan {
  final String title;
  final String subTitle;
  final String total;
  final String desc;
  final String productId;
  final bool popular;
  const _PumoPremiumPlan({
    required this.title,
    required this.subTitle,
    required this.total,
    required this.desc,
    required this.productId,
    required this.popular,
  });
}

class _PumoPremiumPrivilegeItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PumoPremiumPrivilegeItem({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PumoTheme.primaryColor, PumoTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: PumoTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: PumoTheme.secondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class _Privilege {
  final IconData icon;
  final String text;
  const _Privilege({required this.icon, required this.text});
}