package com.example.papaleguas_pix

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager.LayoutParams
import android.view.View
import android.view.WindowManager
import android.os.Build
import android.os.Bundle
import android.webkit.WebView
import android.webkit.CookieManager
import android.content.pm.PackageManager
import android.Manifest
import android.webkit.WebSettings
import android.content.Context
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import androidx.annotation.RequiresApi

class MainActivity: FlutterActivity() {
    private val SECURE_CHANNEL = "flutter_secure"
    private val SECURITY_CHECKER_CHANNEL = "security_checker"
    private var isContentHidden = false
    
    // Configuração para permitir tráfego de rede não criptografado (apenas para desenvolvimento)
    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Configurações de segurança do WebView
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            WebView.setDataDirectorySuffix("supabase")
        }
        
        // Habilita depuração do WebView apenas em modo desenvolvimento
        if (BuildConfig.DEBUG) {
            WebView.setWebContentsDebuggingEnabled(true)
        }
        
        // Configura o WebView para melhor desempenho
        setupWebViewDefaults()
        
        // Verifica e solicita permissões em tempo de execução (Android 6.0+)
        checkAndRequestPermissions()
    }
    
    private fun setupWebViewDefaults() {
        // Configurações padrão para WebView
        val webSettings = WebView(this).settings
        webSettings.javaScriptEnabled = true
        webSettings.domStorageEnabled = true
        webSettings.databaseEnabled = true
        webSettings.cacheMode = WebSettings.LOAD_DEFAULT
        webSettings.loadWithOverviewMode = true
        webSettings.useWideViewPort = true
        webSettings.setSupportZoom(true)
        webSettings.builtInZoomControls = true
        webSettings.displayZoomControls = false
        
        // Configuração de segurança
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            webSettings.safeBrowsingEnabled = true
        }
        
        // Configuração de cookies
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.setAcceptThirdPartyCookies(WebView(this), true)
        }
    }
    
    private fun checkAndRequestPermissions() {
        val permissions = mutableListOf<String>()
        
        // Verifica e adiciona permissões necessárias
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.INTERNET
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.INTERNET)
        }
        
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_NETWORK_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.ACCESS_NETWORK_STATE)
        }
        
        // Se houver permissões para solicitar, solicita ao usuário
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissions.toTypedArray(),
                1001
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Canal para proteção contra screenshots e segurança
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    window.addFlags(LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "disableSecure" -> {
                    window.clearFlags(LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "preventBackgroundPreview" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        WindowManager.LayoutParams.FLAG_SECURE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                    result.success(null)
                }
                "hideContent" -> {
                    if (!isContentHidden) {
                        window.decorView.visibility = View.INVISIBLE
                        isContentHidden = true
                    }
                    result.success(null)
                }
                "showContent" -> {
                    if (isContentHidden) {
                        window.decorView.visibility = View.VISIBLE
                        isContentHidden = false
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Canal para verificação de segurança
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHECKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkMaliciousApps" -> {
                    val packages = call.argument<List<String>>("packages")
                    if (packages != null) {
                        result.success(checkMaliciousApps(packages))
                    } else {
                        result.error("INVALID_ARGUMENT", "Lista de pacotes é nula", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkMaliciousApps(packages: List<String>): Boolean {
        val packageManager = context.packageManager
        for (packageName in packages) {
            try {
                packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
                return true // Se encontrar qualquer app da lista, retorna true
            } catch (e: PackageManager.NameNotFoundException) {
                // App não encontrado, continua verificando
                continue
            }
        }
        return false
    }

    override fun onPause() {
        super.onPause()
        if (isContentHidden) {
            window.decorView.visibility = View.INVISIBLE
        }
    }

    override fun onResume() {
        super.onResume()
        if (isContentHidden) {
            window.decorView.visibility = View.VISIBLE
        }
    }
}
