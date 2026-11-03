/// Textos visibles de la app (español rioplatense).
///
/// Todo texto de la UI se declara acá y no suelto en los widgets.
abstract final class AppStrings {
  static const String appName = 'ClinApp';
  static const String cityName = 'General Alvear';

  // Navegación inferior.
  static const String navHome = 'Inicio';
  static const String navSearch = 'Buscar';
  static const String navOrders = 'Pedidos';
  static const String navProfile = 'Perfil';
  static const String navActiveOrdersBadgeSemantics = 'pedidos en curso';

  // Acciones y estados comunes.
  static const String actionRetry = 'Reintentar';
  static const String actionSeeAll = 'Ver todas';
  static const String actionClose = 'Cerrar';
  static const String actionClear = 'Borrar';
  static const String actionBack = 'Volver';
  static const String showPassword = 'Mostrar contraseña';
  static const String hidePassword = 'Ocultar contraseña';
  static const String genericErrorTitle = 'Algo no salió como esperábamos';
  static const String genericErrorMessage =
      'Revisá tu conexión e intentá de nuevo en unos segundos.';
  static const String errorAuth =
      'Tu sesión venció o los datos no son válidos. Volvé a iniciar sesión.';
  static const String errorAuthCredentials =
      'El correo o la contraseña no son correctos. Verificalos e intentá de nuevo.';
  static const String errorAuthUserExists =
      'Ya existe una cuenta con este correo. Probá iniciando sesión.';
  static const String errorAuthEmailNotConfirmed =
      'Confirmá tu correo electrónico antes de iniciar sesión.';
  static const String errorServer =
      'No pudimos consultar el servidor en este momento. Intentá de nuevo.';
  static const String errorNetwork =
      'No tenés conexión a internet. Revisá tu red e intentá de nuevo.';
  static const String errorTimeout =
      'El servidor tardó demasiado en responder. Probá otra vez en unos momentos.';
  static const String errorNotFound =
      'No pudimos encontrar lo que buscabas. Revisá e intentá de nuevo.';
  static const String errorPermissionDenied =
      'No tenés permisos para realizar esta acción o acceder a estos datos.';
  static const String errorAvatarTooLarge =
      'La imagen supera el tamaño máximo permitido de 2 MB.';
  static const String errorAvatarInvalidMime =
      'Formato de imagen no válido. Usá JPG, PNG o WebP.';
  static const String offlineBannerMessage =
      'Estás sin conexión. Mostrando datos guardados en tu dispositivo.';
  static const String offlineBannerReconnect = 'Reconectar';

  // Pantalla Inicio (Etapa 4).
  static const String homeGreetingPrefix = 'Hola, ';
  static const String homeDefaultUserName = 'Lucas';
  static const String homeDeliverTo = 'Entregar en';
  static const String homeDefaultAddress = 'Av. San Martín 450';
  static const String homeChangeAddressSemantics =
      'Cambiar dirección de entrega';
  static const String homeNotificationsSemantics = 'Notificaciones';
  static const String homeProfileSemantics = 'Ir a tu perfil';
  static const String homeVoiceSearchSemantics = 'Búsqueda por voz';
  static const String homeFiltersSemantics = 'Filtros de búsqueda';
  static const String homeCategoriesTitle = 'Categorías';
  static const String homeAllCategoriesChip = 'Todas';
  static const String homePromoDefaultBadge = 'Beneficio exclusivo';
  static const String homePromoDefaultTitle =
      'Envío gratis en tu primer pedido';
  static const String homePromoCouponPrefix =
      'En locales de General Alvear con el cupón ';
  static const String homePromoCta = 'Aprovechá';
  static const String homeLastOrderTitle = 'Tu último pedido';
  static const String homeLastOrderReceipt = 'Ver recibo';
  static const String homeLastOrderRepeat = 'Pedir de nuevo';
  static const String homeLastOrderDeliveredOnTime = 'Entregado a tiempo';
  static const String homeNearbyTitle = 'Cerca tuyo';
  static const String homeSubtitle = 'Comercios destacados en General Alvear';
  static const String homeViewMapSemantics = 'Ver comercios en el mapa';
  static const String homeFreeDelivery = 'Envío gratis';
  static const String homeDeliveryPrefix = 'Envío ';
  static const String homeMinutesSuffix = ' min';
  static const String homeEmptyCategoryTitle =
      'No hay locales en esta categoría';
  static const String homeEmptyCategorySubtitle =
      'Probá eligiendo otra categoría o mirá todos los comercios.';
  static const String homeResetCategoryFilter = 'Ver todas las categorías';
  static const String homeRemoveFavoriteSemantics = 'Quitar de favoritos';

  // Accesos rápidos de navegación.
  static const String homeGreeting = 'Hola, Lucas';
  static const String homeGoToCheckout = 'Ir al checkout';
  static const String homeOpenCatalog = 'Abrir catálogo de componentes';

  // Pantalla Buscar (Etapa 5).
  static const String searchTitle = 'Buscá platos, locales o bebidas';
  static const String searchHint = 'Buscá platos, locales o bebidas...';
  static const String searchSubtitle =
      'Encontrá lo que tenés ganas de comer hoy.';
  static const String searchAdvancedFiltersSemantics =
      'Abrir filtros avanzados';
  static const String searchRecentTitle = 'Búsquedas recientes';
  static const String searchClearAll = 'Borrar todo';
  static const String searchEmptyHistory = 'Historial limpio';
  static const String searchFilterOpenNow = 'Abierto ahora';
  static const String searchFilterFreeDelivery = 'Envío gratis';
  static const String searchFilterTopRated = 'Mejor calificados';
  static const String searchFilterFastest = 'Más rápido';
  static const String searchSuggestedTitle = 'Locales sugeridos';
  static const String searchResultsTitle = 'Resultados de búsqueda';
  static const String searchAvailableSuffix = ' disponibles';
  static const String searchAvailableSingular = '1 disponible';
  static const String searchSignatureDishLabel = 'Plato insignia';
  static const String searchChefRecommendedLabel = 'Recomendado del chef';

  // Pantallas restantes (Etapas 6-8).
  static const String ordersTitle = 'Tus pedidos';
  static const String ordersActiveTab = 'En curso';
  static const String ordersHistoryTab = 'Historial';
  static const String ordersHistorySectionTitle = 'Historial de pedidos';
  static const String ordersHistorySeeAll = 'Ver todos';
  static const String ordersLoadMore = 'Cargar más pedidos';
  static const String ordersEstimatedArrival = 'Llegada';
  static const String ordersStepConfirmed = 'Confirmado';
  static const String ordersStepPreparing = 'En cocina';
  static const String ordersStepReady = 'Listo';
  static const String ordersStepOnTheWay = 'En camino';
  static const String ordersStepDelivered = 'Llegada';
  static const String ordersStatusDelivered = 'Entregado';
  static const String ordersStatusCancelled = 'Cancelado';
  static const String ordersRemainingPrefix = 'Faltan aproximadamente ';
  static const String ordersExpressDelivery = 'Reparto express';
  static const String ordersToPrefix = 'Hacia: ';
  static const String ordersLiveTrackingCta = 'Seguilo en vivo 📍';
  static const String ordersContactCourierCta = 'Contactar repartidor';
  static const String ordersCallCourierSemantics = 'Llamar repartidor';
  static const String ordersChatCourierSemantics =
      'Enviar mensaje al repartidor';
  static const String ordersReorderButton = 'Pedir de nuevo';
  static const String ordersReceiptSemantics = 'Ver recibo del pedido';
  static const String ordersReceiptTitle = 'Detalle del comprobante';
  static const String ordersReceiptSubtotal = 'Subtotal';
  static const String ordersReceiptDelivery = 'Costo de envío';
  static const String ordersReceiptDiscount = 'Descuento';
  static const String ordersReceiptTip = 'Propina';
  static const String ordersReceiptTotal = 'Total abonado';
  static const String ordersSupportTitle = '¿Tuviste algún problema?';
  static const String ordersSupportSubtitle = 'Soporte local en General Alvear';
  static const String ordersSupportAction = 'Ayuda';
  static const String ordersEmptyActiveTitle = 'No tenés pedidos en curso';
  static const String ordersEmptyActiveSubtitle =
      'Cuando pidas algo rico en General Alvear, vas a poder seguirlo en vivo desde acá.';
  static const String ordersEmptyActiveCta = 'Explorar comercios';
  static const String ordersEmptyHistoryTitle = 'Todavía no hiciste pedidos';
  static const String ordersEmptyHistorySubtitle =
      'Tus pedidos entregados van a aparecer acá para que puedas repetir lo que más te gustó.';
  static const String ordersReorderSuccess =
      'Precios y disponibilidad revalidados con el comercio.';
  static const String ordersCallingCourier =
      'Iniciando llamada con el repartidor...';
  static const String ordersChatSheetTitle = 'Mensaje para el repartidor';
  static const String ordersChatPlaceholder =
      'Escribí un mensaje o instrucción...';
  static const String ordersSendMessage = 'Enviar';
  static const String ordersLiveSheetTitle = 'Seguimiento en vivo';

  static const String profileTitle = 'Perfil';
  static const String profileSubtitle =
      'Gestioná tus direcciones, métodos de pago y cuenta.';
  static const String profileGoToLogin = 'Iniciar sesión';
  static const String checkoutTitle = 'Finalizá tu pedido';
  static const String loginTitle = '¡Qué bueno verte!';
  static const String registerTitle = 'Creá tu cuenta';

  // Autenticación (Etapa 8).
  static const String loginHeaderTitle = 'Iniciar Sesión';
  static const String loginHeroBadge = 'Alvear';
  static const String loginWelcomeTitle = '¡Qué bueno verte!';
  static const String loginWelcomeSubtitle =
      'Pedí lo más rico de General Alvear directo a tu puerta.';
  static const String loginIdentifierLabel = 'Teléfono o Correo';
  static const String loginIdentifierHint = '2625 458812 o tu correo';
  static const String loginPasswordLabel = 'Contraseña';
  static const String loginPasswordHint = '••••••••••••';
  static const String loginForgotPassword = '¿Te la olvidaste?';
  static const String loginSubmitCta = 'Iniciar sesión';
  static const String loginOrContinueWith = 'o continuá con';
  static const String loginNoAccountPrompt = '¿No tenés cuenta todavía?';
  static const String loginCreateAccountLink = 'Creá tu cuenta gratis';
  static const String loginLocalSeal =
      '🍇 Delivery 100% alvearense • Mendoza 🍷';
  static const String loginResetPasswordTitle = 'Recuperá tu contraseña';
  static const String loginResetPasswordSubtitle =
      'Ingresá tu correo para recibir las instrucciones de recuperación.';
  static const String loginResetPasswordSent =
      'Te enviamos un enlace a tu correo para restablecer la contraseña.';
  static const String loginResetAction = 'Enviar enlace';

  static const String registerHeaderTitle = 'Registro';
  static const String registerHeroBadge = 'ALVEAR';
  static const String registerPromoPrefix = 'Recibí ';
  static const String registerPromoGift = '\$2.000 de regalo';
  static const String registerPromoMiddle =
      ' y envío gratis en tu primer pedido con el cupón ';
  static const String registerPromoCoupon = 'ALVEARYA';
  static const String registerFullNameLabel = 'Nombre y Apellido';
  static const String registerFullNameHint = 'Ej: Lucas Benítez';
  static const String registerPhoneLabel = 'Teléfono celular';
  static const String registerPhonePrefix = '+54 9 2625';
  static const String registerPhoneHint = '40-1234';
  static const String registerPhoneHelper =
      'Para coordinar la entrega y avisos por WhatsApp';
  static const String registerEmailLabel = 'Correo electrónico';
  static const String registerEmailHint = 'tuemail@ejemplo.com';
  static const String registerPasswordHint = 'Mínimo 8 caracteres';
  static const String registerPasswordWeak = 'Débil';
  static const String registerPasswordFair = 'Regular';
  static const String registerPasswordGood = 'Buena';
  static const String registerPasswordStrong = 'Segura ✓';
  static const String registerTermsPrefix = 'Acepto los ';
  static const String registerTermsLink = 'Términos y Condiciones';
  static const String registerPrivacyLink = 'Política de Privacidad';
  static const String registerTermsSuffix = ' de ClinApp en General Alvear.';
  static const String registerSubmitCta = 'Crear mi cuenta';
  static const String registerOrSignUpWith = 'O registrate con';
  static const String registerHasAccountPrompt = '¿Ya tenés cuenta?';
  static const String registerSignInLink = 'Iniciá sesión acá';
  static const String registerSupportBadge =
      'Atención y soporte local en General Alvear 24/7';

  // Validaciones en español rioplatense.
  static const String validationRequiredIdentifier =
      'Ingresá tu teléfono o correo electrónico.';
  static const String validationInvalidIdentifier =
      'Ingresá un correo o número celular válido.';
  static const String validationRequiredName = 'Ingresá tu nombre y apellido.';
  static const String validationShortName =
      'El nombre debe tener al menos 3 caracteres.';
  static const String validationRequiredPhone =
      'Ingresá tu número de teléfono.';
  static const String validationInvalidPhone =
      'El número debe contener entre 6 y 8 dígitos.';
  static const String validationRequiredEmail =
      'Ingresá tu correo electrónico.';
  static const String validationInvalidEmail = 'El correo no es válido.';
  static const String validationRequiredPassword = 'Ingresá una contraseña.';
  static const String validationShortPassword =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String validationAcceptTerms =
      'Tenés que aceptar los términos y condiciones para continuar.';

  // Perfil y Configuración (Etapa 8).
  static const String profileVerifiedBadge = 'Usuario Verificado';
  static const String profileChangePhotoSemantics = 'Cambiar foto de perfil';
  static const String profilePhotoUpdated = 'Foto de perfil actualizada.';
  static const String profileMetricOrders = 'Pedidos';
  static const String profileMetricSpent = 'Total gastado';
  static const String profileMetricRating = 'Calificación';

  // Gestión y administración (paneles por rol).
  static const String profileManagementSection = 'GESTIÓN Y ADMINISTRACIÓN';
  static const String profileAdminPanelTitle = 'Panel Admin';
  static const String profileAdminPanelSubtitle =
      'Gestión central de la plataforma';
  static const String profileMerchantPanelTitle = 'Mi Local';
  static const String profileMerchantPanelSubtitle = 'Ir al panel de comercio';
  static const String profileCourierPanelTitle = 'Panel Repartidor';
  static const String profileCourierPanelSubtitle = 'Ir al panel de repartidor';

  // Cuenta & General.
  static const String profileAccountSection = 'CUENTA & GENERAL';
  static const String profileAddressesTitle = 'Mis direcciones';
  static const String profileAddressesSubtitle =
      'Gestionar direcciones de entrega';
  static const String profilePaymentMethodsTitle = 'Métodos de pago';
  static const String profilePaymentMethodsSubtitle = 'Efectivo, Mercado Pago';
  static const String profileFavoritesTitle = 'Mis Favoritos';
  static const String profileFavoritesSubtitle = 'Comercios guardados';
  static const String profileNotificationsTitle = 'Notificaciones';
  static const String profileNotificationsSubtitle = 'Historial de alertas';
  static const String profileCouponsTitle = 'Mis cupones';
  static const String profileCouponsEmptySubtitle = 'Sin cupones disponibles';
  static const String profileHelpTitle = 'Ayuda y soporte';
  static const String profileHelpSubtitle = 'Preguntas frecuentes';
  static const String profileSettingsTitle = 'Configuración';
  static const String profileSettingsSubtitle = 'Privacidad y cuenta';

  static const String profileSignOutCta = 'Cerrar sesión';
  static const String profileVersionFooter =
      'Clin • v1.0.4 • General Alvear, Mendoza';

  // Hojas de detalle de Perfil.
  static const String profileNewAddressAction = 'Agregar nueva dirección';
  static const String profileNoAddresses = 'No tenés direcciones guardadas.';
  static const String profileNoFavorites =
      'No tenés comercios guardados en favoritos.';
  static const String profileNoNotifications =
      'No tenés notificaciones nuevas.';
  static const String profileClearNotifications = 'Limpiar todas';
  static const String profileThemeModeTitle = 'Tema de la aplicación';
  static const String profileThemeModeSystem = 'Sistema';
  static const String profileThemeModeDark = 'Oscuro';
  static const String profileThemeModeLight = 'Claro';
  static const String profileSettingsThemeTitle =
      'Calidad de vidrio (GlassQuality)';
  static const String profileSettingsHighQualityDesc =
      'Efecto completo con blur en tiempo real.';
  static const String profileSettingsLowQualityDesc =
      'Superficies translúcidas sin blur (modo económico).';
  static const String profileSettingsRoleTitle = 'Rol de usuario activo (Demo)';
  static const String profileRoleClient = 'Cliente';
  static const String profileRoleMerchant = 'Comercio (Mi Local)';
  static const String profileRoleCourier = 'Repartidor';
  static const String profileRoleAdmin = 'Administrador';
  static const String profileRoleSwitchedPrefix = 'Rol cambiado a ';

  // Pantalla Checkout y Pagos (Etapa 7).
  static const String checkoutHeaderTitle = 'Detalle del comercio';
  static const String checkoutFinalStepLabel = 'PASO FINAL';
  static const String checkoutEncryptedBadge = 'Cifrado seguro';
  static const String checkoutItemsSingleSuffix = 'plato';
  static const String checkoutItemsPluralSuffix = 'platos';
  static const String checkoutDecreaseQtySemantics = 'Disminuir cantidad';
  static const String checkoutIncreaseQtySemantics = 'Aumentar cantidad';
  static const String checkoutEmptyCartTitle = 'Tu carrito está vacío';
  static const String checkoutEmptyCartSubtitle =
      'Sumá platos de tus comercios favoritos de General Alvear para continuar.';
  static const String checkoutEmptyCartCta = 'Volver al inicio';
  static const String checkoutAddressTitle = 'Dirección de entrega';
  static const String checkoutAddressChange = 'Cambiar';
  static const String checkoutAddressSelectSheetTitle =
      'Elegí dónde recibir tu pedido';
  static const String checkoutEstimatedDeliveryPrefix = 'Entrega estimada: ';
  static const String checkoutRiderNotesLabel = 'Instrucciones para el rider';
  static const String checkoutRiderNotesHint =
      '¿Alguna indicación? Ej: Tocar timbre...';
  static const String checkoutPaymentTitle = 'Método de pago';
  static const String checkoutProtectedBadge = '100% Protegido';
  static const String checkoutMethodMpTitle = 'Mercado Pago';
  static const String checkoutMethodMpSubtitle =
      'Dinero en cuenta o débito inmediato';
  static const String checkoutMethodCardTitle = 'Visa Débito';
  static const String checkoutMethodCardSubtitle = '•••• 4129';
  static const String checkoutMethodCashTitle = 'Efectivo contra entrega';
  static const String checkoutMethodCashSubtitle =
      'Abonás en mano al recibir el pedido';
  static const String checkoutMethodClinPayTitle = 'ClinPay (Saldo en cuenta)';
  static const String checkoutMethodClinPaySubtitle =
      'Abonás al instante con tu billetera';
  static const String checkoutClinPayBalanceAvailable = 'Saldo disponible: ';
  static const String checkoutClinPayInsufficientBalance =
      'Saldo insuficiente en ClinPay';
  static const String checkoutPaymentClinPayConfirmedMsg =
      '¡Pedido confirmado! Pagado con saldo ClinPay.';
  static const String checkoutMethodMpPhase6Notice = 'Pago online';
  static const String checkoutCashChangeForLabel =
      '¿Con cuánto abonás? (opcional)';
  static const String checkoutCashChangeForHint =
      'Ej: 15000 para preparar tu vuelto';

  // Discrepancia de precios y autoridad de servidor
  static const String checkoutPriceDiscrepancyTitle =
      'Actualización de precios';
  static const String checkoutPriceDiscrepancySubtitle =
      'El local o las tarifas actualizaron el valor de tu pedido. Revisá el nuevo total antes de continuar:';
  static const String checkoutPriceDiscrepancyPreviousTotal =
      'Total estimado anterior:';
  static const String checkoutPriceDiscrepancyNewTotal =
      'Nuevo total verificado:';
  static const String checkoutPriceDiscrepancyDifference = 'Diferencia:';
  static const String checkoutPriceDiscrepancyAccept =
      'Aceptar nuevo total y pedir';
  static const String checkoutPriceDiscrepancyReview = 'Revisar carrito';

  // Errores de negocio de la Edge Function
  static const String checkoutErrorStoreClosed =
      'El local está cerrado en este momento. Consultá sus horarios de atención.';
  static const String checkoutErrorStoreUnavailable =
      'El comercio no está disponible en este momento.';
  static const String checkoutErrorOutOfZone =
      'La dirección de entrega está fuera de la zona de cobertura en General Alvear.';
  static const String checkoutErrorMaxDistance =
      'La dirección supera el radio máximo de entrega permitido.';
  static const String checkoutErrorProductUnavailable =
      'Uno de los platos ya no está disponible. Modificá tu pedido.';
  static const String checkoutErrorFirstOrderCoupon =
      'Este cupón es de bienvenida y solo aplica para tu primer pedido.';
  static const String checkoutCouponTitle = 'Cupón de descuento';
  static const String checkoutCouponHint = 'Ingresá tu cupón';
  static const String checkoutCouponApply = 'Aplicar';
  static const String checkoutCouponRemove = 'Quitar';
  static const String checkoutCouponAppliedPrefix = "CUPÓN '";
  static const String checkoutCouponAppliedSuffix = "' APLICADO";
  static const String checkoutCouponInvalid =
      'El cupón ingresado no es válido, venció o no alcanza el mínimo.';
  static const String checkoutBreakdownTitle = 'Detalle del pago';
  static const String checkoutSubtotalLabel = 'Subtotal';
  static const String checkoutDeliveryLabel = 'Costo de envío';
  static const String checkoutFreeBadge = 'GRATIS';
  static const String checkoutDiscountLabel = 'Descuento exclusivo';
  static const String checkoutTotalLabel = 'Total a pagar';
  static const String checkoutTaxesIncluded = 'Impuestos locales incluidos';
  static const String checkoutEstimatedNote =
      'Estimación · verificando con el servidor';
  static const String checkoutServerVerifiedNote =
      'Total verificado con el servidor';
  static const String checkoutFinalTotalLabel = 'Total final';
  static const String checkoutPayButtonPrefix = 'Pagar ';
  static const String checkoutSubmittingLabel = 'Procesando...';
  static const String paymentProcessingTitle = 'Esperando confirmación de pago';
  static const String paymentProcessingSubtitle =
      'Completá el pago en Mercado Pago. Estamos sincronizando el estado en tiempo real.';
  static const String paymentApprovedTitle = '¡Pago aprobado!';
  static const String paymentApprovedSubtitle =
      'El comercio ya recibió tu pedido y empezó a prepararlo.';
  static const String paymentPendingTitle = 'Pago pendiente de acreditación';
  static const String paymentPendingSubtitle =
      'Apenas Mercado Pago acredite el pago, el comercio recibirá tu pedido.';
  static const String paymentRejectedTitle = 'No pudimos procesar el pago';
  static const String paymentRejectedSubtitle =
      'El medio de pago fue rechazado o cancelaste la operación. Probá con otro método.';
  static const String paymentCashConfirmedMsg =
      '¡Pedido confirmado! Abonás en efectivo al recibir.';
  static const String paymentSimulateApproveAction =
      'Confirmar pago aprobado (Sandbox)';
  static const String paymentSimulateRejectAction = 'Simular rechazo';
  static const String paymentRetryAction = 'Elegir otro medio de pago';
  static const String paymentRetryMercadoPagoAction =
      'Reintentar con Mercado Pago';
  static const String paymentChangeMethodAction = 'Cambiar medio de pago';
  static const String paymentTimeoutTitle =
      'El pago está demorando en confirmarse';
  static const String paymentTimeoutSubtitle =
      'Tu entidad bancaria o Mercado Pago aún no confirmaron la acreditación. Si ya se debitó el dinero, tu pedido se confirmará automáticamente y podés seguirlo en vivo desde Mis Pedidos.';
  static const String paymentUserCancelledSubtitle =
      'Cancelaste la operación en Mercado Pago. Tu pedido sigue reservado: podés reintentar abonar o cambiar el medio de pago.';
  static const String paymentAwaitingReturn =
      'Volviste de Mercado Pago. Aguardando confirmación del servidor...';
  static const String paymentGoToOrdersAction = 'Seguir mi pedido';

  // Pantalla de verificación de fundamentos (Etapa 1).
  static const String foundationTitle = 'Fundamentos de diseño';
  static const String foundationSubtitle = 'Tipografía, colores y formato.';
  static const String foundationDisplay = 'Pedí lo más rico';
  static const String foundationHeadline = 'Elegí tu comercio';
  static const String foundationBody = 'Seguilo en vivo hasta tu puerta.';
  static const String foundationLabel = 'Buscá platos, locales o bebidas';
  static const String foundationPriceLabel = 'Total a pagar';

  // Catálogo de componentes Liquid Glass (Etapa 2).
  static const String catalogTitle = 'Catálogo Liquid Glass';
  static const String catalogSubtitle =
      'Componentes compartidos en General Alvear';
  static const String catalogQualityLabel = 'Calidad visual del vidrio';
  static const String catalogQualityHigh = 'Alta (Blur)';
  static const String catalogQualityLow = 'Baja (Sin blur)';
  static const String catalogButtonsSection = 'Botones y acciones';
  static const String catalogPrimaryCta = 'Pedí ahora';
  static const String catalogSecondaryCta = 'Ver recibo';
  static const String catalogFavoriteSemantics = 'Guardar en favoritos';
  static const String catalogOpenSheet = 'Abrir panel inferior';
  static const String catalogSheetTitle = 'Detalle de entrega';
  static const String catalogSheetBody =
      'Tu pedido se prepara en el momento y lo seguís en vivo hasta tu puerta.';
  static const String catalogInputsSection = 'Campos de texto y búsqueda';
  static const String catalogSearchHint = '¿Qué se te antoja hoy?';
  static const String catalogPasswordHint = 'Ingresá tu contraseña';
  static const String catalogChipsSection = 'Categorías y filtros';
  static const String catalogChipPizzas = 'Pizzas';
  static const String catalogChipBurgers = 'Hamburguesas';
  static const String catalogChipEmpanadas = 'Empanadas';
  static const String catalogCardsSection = 'Tarjetas y comercio';
  static const String catalogMerchantName = 'Pizzería La Alvearense';
  static const String catalogMerchantTag = 'Pizzas a la piedra';
  static const String catalogMerchantMeta = '20-30 min · Envío ';
  static const String catalogStatusOnline = 'En línea';
  static const String catalogStatusDelivered = 'Entregado a tiempo';
  static const String catalogStatusPreparing = 'En cocina';
  static const String catalogStatesSection = 'Estados de pantalla';
  static const String catalogEmptyTitle = '¿No encontrás lo que buscabas?';
  static const String catalogEmptySubtitle =
      'Probá con otra búsqueda o explorá los comercios destacados de General Alvear.';
  static const String catalogExploreMerchants = 'Ver todos los comercios';

  // Paneles de roles (Repartidor, Local y Administrador).
  // Panel Repartidor.
  static const String courierPanelTitle = 'Panel Repartidor';
  static const String courierPanelBadge = 'CLIN!';
  static const String courierPanelSubtitle = 'General Alvear · Modo trabajo';
  static const String courierStatusInService = 'En servicio';
  static const String courierStatusPaused = 'Pausado';
  static const String courierShiftActive = 'Turno Activo';
  static const String courierShiftSubtitle =
      'entregas asignadas · Gral. Alvear';
  static const String courierGpsActive = 'GPS Activo';
  static const String courierTabAssigned = 'Asignados';
  static const String courierTabPreparing = 'En preparación';
  static const String courierTabAvailable = 'Disponibles';
  static const String courierTabHistory = 'Historial';
  static const String courierPickupPoint = 'Punto de retiro';
  static const String courierDeliveryPoint = 'Dirección de entrega';
  static const String courierStreetDoorTag = 'Puerta a la calle';
  static const String courierActionViewRoute = 'Ver ruta';
  static const String courierActionChat = 'Chat';
  static const String courierActionCall = 'Llamar';
  static const String courierActionViewMerchant = 'Ver local';
  static const String courierActionOrderDelivered = 'Entregué el pedido';
  static const String courierActionOrderPickedUp = 'Retiré el pedido';
  static const String courierActionViewDetails = 'Ver detalle';
  static const String courierStatusOnTheWay = 'En camino';
  static const String courierStatusReadyPickup = 'Listo para retirar';
  static const String courierStatusInKitchen = 'En preparación';
  static const String courierCashToCollect = 'Efectivo a cobrar';
  static const String courierPaidOnline = 'Pagado online (Mercado Pago)';
  static const String courierDistanceEstimate =
      'A 1.2 km de la entrega (~4 min)';
  static const String courierNoTollsBadge = 'Sin peajes';
  static const String courierKitchenNotice =
      'Hamburguesas en parrilla · Te avisaremos cuando esté listo para retirar';
  static const String courierEarningsTodayTitle = 'Ganancias del día';
  static const String courierEarningsTodaySubtitle = 'Hoy en General Alvear';
  static const String courierDeliveriesDoneCount = 'entregas completadas';
  static const String courierOrderDeliveredSuccess =
      '¡Pedido entregado con éxito!';
  static const String courierOrderPickedUpSuccess =
      '¡Pedido retirado! En camino al destino.';
  static const String courierEmptyAssigned =
      'No tenés pedidos asignados en este momento.';

  // Panel Mi Local (Comercio).
  static const String merchantPanelHeaderTitle = 'Panel Mi Local';
  static const String merchantPanelBadge = 'LOCAL';
  static const String merchantPanelSubtitle =
      'Paso de los Andes 142 · Gral. Alvear';
  static const String merchantStatusOpen = 'Local Abierto';
  static const String merchantStatusClosed = 'Pausado';
  static const String merchantTabNew = 'Nuevos';
  static const String merchantTabKitchen = 'En cocina';
  static const String merchantTabReady = 'Listos';
  static const String merchantTabMenu = 'Menú y Stock';
  static const String merchantAvgPrepTime = 'Tiempo prom. cocina: 18 min';
  static const String merchantHighDemandTag = 'Demanda alta';
  static const String merchantActionAcceptKitchen = 'Aceptar y cocinar';
  static const String merchantActionReject = 'Rechazar';
  static const String merchantActionMarkReady = 'Marcar listo para retirar';
  static const String merchantActionDispatch = 'Entregado al repartidor';
  static const String merchantAssignedRider = 'Repartidor asignado';
  static const String merchantTodayRevenue = 'Caja acumulada hoy';
  static const String merchantOrdersCompletedToday = 'pedidos despachados hoy';
  static const String merchantEmptyOrders = 'No hay pedidos en esta sección.';
  static const String merchantStockAvailable = 'En menú';
  static const String merchantStockPaused = 'Pausado';

  // Panel Admin.
  static const String adminPanelHeaderTitle = 'Panel Admin';
  static const String adminPanelBadge = 'ALVEAR';
  static const String adminPanelSubtitle = 'Monitoreo en vivo · General Alvear';
  static const String adminSystemStatus = 'Sistema 100% operativo';
  static const String adminTabSummary = 'Resumen';
  static const String adminTabMerchants = 'Comercios';
  static const String adminTabCouriers = 'Repartidores';
  static const String adminTabRates = 'Tarifas';
  static const String adminKpiActiveOrders = 'Pedidos activos';
  static const String adminKpiActiveCouriers = 'Riders en calle';
  static const String adminKpiOpenMerchants = 'Locales abiertos';
  static const String adminKpiAvgDeliveryTime = 'Tiempo prom.';
  static const String adminGmvTitle = 'Volumen total transaccionado hoy';
  static const String adminPlatformCommissions =
      'Comisiones de plataforma estimadas';
  static const String adminMerchantEnabled = 'Operando';
  static const String adminMerchantPaused = 'Suspendido';
  static const String adminBaseDeliveryFee = 'Tarifa base de envío en Alvear';
  static const String adminSaveRateSuccess =
      'Tarifa actualizada correctamente.';

  // Notificaciones push.
  static const String notificationViewOrder = 'Ver pedido';
  static const String notificationDefaultTitle = 'Actualización de tu pedido';
  static const String notificationDismiss = 'Cerrar';

  // Privacidad, Términos y Eliminación de Cuenta (Release Android/iOS).
  static const String privacyPolicyTitle =
      'Política de Privacidad y Uso de Datos';
  static const String privacyPolicySubtitle =
      'Cómo protegemos tus datos en General Alvear.';
  static const String privacyPolicyBody =
      'ClinApp recopila únicamente tu nombre, teléfono, correo electrónico y direcciones en General Alvear para procesar y entregar tus pedidos.\n\n'
      '• Pagos seguros: Los pagos se procesan a través de Mercado Pago; ClinApp nunca almacena datos de tarjetas en tu dispositivo.\n'
      '• Ubicación y reparto: Las coordenadas de tu dirección solo son visibles para el comercio y el repartidor asignado a tu pedido.\n'
      '• Derechos ARCO y baja: Podés editar tus datos o eliminar tu cuenta y toda tu información personal en cualquier momento desde Configuración > Eliminar mi cuenta.';
  static const String deleteAccountSectionTitle = 'Zona de privacidad y cuenta';
  static const String deleteAccountCta = 'Eliminar mi cuenta';
  static const String deleteAccountConfirmTitle =
      '¿Querés eliminar tu cuenta de ClinApp?';
  static const String deleteAccountConfirmBody =
      'Esta acción es permanente. Se borrarán tu perfil, direcciones guardadas, favoritos y tokens de notificación. No podrás deshacer este cambio.';
  static const String deleteAccountCancel = 'Cancelar';
  static const String deleteAccountConfirmAction = 'Sí, eliminar mi cuenta';
  static const String deleteAccountSuccess =
      'Tu cuenta y tus datos personales fueron eliminados.';
  static const String deleteAccountActiveOrdersError =
      'No podés eliminar tu cuenta mientras tengas pedidos en curso.';
}
