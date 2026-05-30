plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.urubu_do_pix_novo"
    compileSdk = 34
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
    
    // Configuração para reduzir o tamanho do APK
    bundle {
        language {
            // Desativa a divisão por idioma, já que o Flutter já tem suporte a múltiplos idiomas
            enableSplit = false
        }
        density {
            // Habilita a divisão por densidade de tela
            enableSplit = true
        }
        abi {
            // Habilita a divisão por arquitetura do processador
            enableSplit = true
        }
    }
    
    // Configuração para builds de release
    buildTypes {
        release {
            // Habilita o código ofuscado e a otimização
            isMinifyEnabled = true
            isShrinkResources = true
            // Usa o ProGuard para ofuscar e otimizar o código
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    defaultConfig {
        applicationId = "com.example.urubu_do_pix_novo"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
}
