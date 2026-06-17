import 'package:spt/core/auth/token_storage_base.dart';
import 'package:spt/core/auth/token_storage_stub.dart'
    if (dart.library.html) 'package:spt/core/auth/token_storage_web.dart'
    if (dart.library.io) 'package:spt/core/auth/token_storage_native.dart'
    as token_storage_impl;

final TokenStorage tokenStorage = token_storage_impl.createTokenStorage();
