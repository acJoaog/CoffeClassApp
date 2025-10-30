# TensorFlow Lite GPU Delegate (mantém classes necessárias)
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }

# TFLite core
-keep class org.tensorflow.lite.** { *; }

# Evita remover classes carregadas via reflexão
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Evita warnings de bibliotecas nativas
-dontwarn org.tensorflow.lite.**