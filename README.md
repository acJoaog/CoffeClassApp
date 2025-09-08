# CoffeeClass - Classificador de Imagens no Android

CoffeeClass é um aplicativo Android que utiliza **TensorFlow Lite** para classificar imagens capturadas pela câmera do dispositivo. O app captura **3 fotos consecutivas**, realiza a classificação de cada uma e exibe como resultado a **classe mais frequente** entre as 3 fotos.

---

## Funcionalidades

- Captura de imagens usando a câmera do dispositivo.
- Classificação de imagens usando modelo TFLite.
- Captura múltipla (3 fotos) antes da classificação final.
- Exibição da **classe mais frequente** como resultado.
- Layout moderno e responsivo com `CardView` e `ConstraintLayout`.

---

## Tecnologias e Bibliotecas

- Android Studio
- Java
- TensorFlow Lite
- ConstraintLayout e CardView para interface
- Camera via `Intent` padrão do Android

---

## Estrutura do Projeto

```bash
app/
├─ src/main/java/com/example/coffeclass/
│ ├─ MainActivity.java # Lógica principal de captura e classificação
│ └─ TFLiteHelper.java # Classe de suporte para carregar e rodar o modelo TFLite
├─ res/layout/
│ └─ activity_main.xml # Layout principal
├─ assets/
│ ├─ model.tflite # Modelo treinado (float32)
│ └─ labels.txt # Labels do modelo
└─ AndroidManifest.xml # Permissões e configuração do app
```
---

## Classificação
- O modelo testado utiliza o formato  float32.
---

## Labels

- O arquivo labels.txt utiliza o seguinte formato como no exemplo implementado:
```bash
DuroRiadoRio
Mole
Quebrado
RiadoRio
RioFechado
```
---

## Configuração

1. Clone ou baixe o projeto.
2. Abra o projeto no **Android Studio**.
3. Certifique-se de adicionar as permissões no `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />