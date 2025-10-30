# Coffee Class – Classificador de Grãos de Café com IA

**Coffee Class** é um aplicativo Flutter que utiliza **inteligência artificial (TensorFlow Lite)** para classificar grãos de café em tempo real com a câmera do celular.  
Desenvolvido para **produtores, baristas e entusiastas do café**, o app identifica automaticamente os tipos de grãos com precisão.

---

📦 [Baixar APK](https://github.com/acJoaog/CoffeClassApp/releases/download/v1.3/coffe_class.apk)

## Funcionalidades

- **Captura automática de 3 fotos** com intervalo de 0.5s  
- **Classificação em tempo real** com modelo `.tflite` (256x256, NCHW)  
- **Resultado médio robusto** (média das 3 fotos)  
- **Botão "Nova Captura"** com animação suave  
- **Tema minimalista elegante** (Light Mode) com paleta de café  
- **Preview da câmera**  
- **Layout responsivo** (funciona em qualquer tela)  

---

## Paleta de Cores (Light Mode Café)

| Cor | Uso | Hex |
|-----|-----|-----|
| Branco | Fundo | `#FFFFFF` |
| Preto | Texto | `#000000` |
| Verde Café | Botão "Nova Captura" | `#4A7C59` |
| Bege Claro | Texto/Bordas | `#795548` |

---

## Tecnologias

- **Flutter** (Dart)
- **TensorFlow Lite** (`tflite_flutter`)
- **Camera** (`camera` plugin)
- **Image Processing** (`image` package)
- **Material 3** (Design moderno)

---

## Estrutura do Projeto

```bash
lib/
├── main.dart               → Tela principal com câmera e classificação
├── services/
│   └── classifier_service.dart → Lógica do modelo TFLite
assets/
├── model.tflite            → Modelo treinado (256x256, NCHW, float32)
└── labels.txt              → Classes: Duro, Mole, RioZona, etc.
```

---

## Como Rodar

### 1. *Clone o repositório*
```bash
git clone https://github.com/seu-usuario/CoffeClassApp.git
cd CoffeClassApp
```

---

### 2. *Instale as dependências*
```bash
flutter pub get
```

---

### 3. *Adicione os assets*

Certifique-se de que:

 - assets/model.tflite
 - assets/labels.txt

estão na pasta assets/ e declarados no pubspec.yaml:
```bash
flutter pub get
```

---

### 4. *Rode o app*
```bash
flutter run
```

---

### 5. *Build do APK*
```bash
flutter build apk --release
```
- Arquivo gerado:
```bash
build/app/outputs/flutter-apk/app-release.apk
```
---