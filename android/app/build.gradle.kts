import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리스 서명 — work/key.properties + work/loop-release.jks (커밋 금지, 루트 .gitignore의 work/ 제외).
// work/key.properties가 없으면(다른 머신 등) 기존처럼 debug 키로 폴백해 flutter run --release가 깨지지 않게.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("../work/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.loop.loop"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications가 요구 — java.time 등을 구버전 API에서 쓸 수 있게 해줌
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Play 스토어 고유 ID — com.loop.loop은 이미 사용 중이라 계정 아이디로 (2026-10-20).
        // 코드 패키지(namespace)는 com.loop.loop 그대로 — 둘은 달라도 된다.
        // ⚠️ Play Console에 등록한 뒤에는 영구 고정.
        applicationId = "com.devnoyo0123.loop"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // JVM 단위 테스트에서 android.jar 스텁이 예외 대신 기본값을 돌려주게 —
    // NearbyBridge는 Android 프레임워크를 거의 안 쓰지만 Payload 내부가 쓸 수 있다.
    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    buildTypes {
        debug {
            // 플레이 설치본(앱 서명 키)과 공존 — 핫픽스 검증용 별칭 앱. (2026-11-06)
            applicationIdSuffix = ".dev"
        }
        release {
            // key.properties가 있으면 릴리스 키, 없으면 debug 키로 폴백.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 축소·난독화 — Play Console "DEX 코드 최적화 기준점 미만(난독화 0%)"
            // 해결 (2026-11-11, 기한 2027-02). 2026-10-18엔 광고 SDK가 끌어오는
            // WorkManager(Room)의 리플렉션 생성자(WorkDatabase_Impl)가 깨져
            // 시작 크래시가 났다 — proguard-rules.pro의 keep 규칙으로 막는다.
            // 매핑 파일은 AAB에 포함되어 Play가 자동으로 가져간다.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // play-services-ads(광고 SDK)가 androidx.work 2.7.0을 끌어오는데, 이 구버전은
    // Android 16에서 WorkDatabase 생성 실패로 앱이 시작하자마자 크래시난다.
    // 최신 WorkManager로 강제 상향 — 하위 호환이므로 광고 SDK에도 문제 없다.
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    // 사슬 공유 — Nearby Connections 직접 연동(NearbyBridge). Flutter 플러그인은
    // STREAM을 지원하지 않아 수신 파일이 Downloads에 남는다. share-design.md §6.6
    implementation("com.google.android.gms:play-services-nearby:19.3.0")
    // NearbyBridge·ShareStreamWriter JVM 단위 테스트 (./gradlew :app:testDebugUnitTest)
    testImplementation("junit:junit:4.13.2")
}
