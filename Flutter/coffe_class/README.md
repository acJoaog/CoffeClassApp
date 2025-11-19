# Coffee Class – Classificador de Grãos de Café com IA

**Coffee Class** é um aplicativo Flutter que utiliza **inteligência artificial (TensorFlow Lite)** para classificar grãos de café em tempo real com a câmera do celular.  
Desenvolvido para **produtores, baristas e entusiastas do café**, o app identifica automaticamente os tipos de grãos com **alta precisão e robustez** graças a **data augmentation e votação ponderada**.

---

📦[Baixar APK](https://github.com/acJoaog/CoffeClassApp/releases/download/v1.6/coffe_class.apk)

## Funcionalidades

- Captura automática de **3** fotos com intervalo de **0.6s**  
- As 3 fotos são analisadas individualmente pelo modelo **TFLite**
- Dois modos de decisão da predição final:  
  - **Média das Confianças** da Classe Mais Frequente  
  - **Maior Confiança** Absoluta
- **Botão "Nova Captura"** com animação suave  
- **Tema minimalista elegante** (Light Mode) com paleta de café  
- **Preview da câmera**  
- **Layout responsivo** (funciona em qualquer tela)  

---

## Mudança de Modo

- Após classificar, o usuário pode alternar entre “Média das Confianças” e “Maior Confiança”.
- O app recalcula e atualiza o resultado exibido.

---

## Paleta de Cores (Light Mode Café)

| Cor           | Uso                    | Hex         |
|---------------|------------------------|-------------|
| Branco        | Fundo                  | `#FFFFFF`   |
| Preto         | Texto                  | `#000000`   |
| Verde Café    | Botão "Classificar"    | `#4A7C59`   |
| Marrom        | Bordas e texto         | `#795548`   |

---

## Tecnologias

- **Flutter** (Dart)
- **TensorFlow Lite** (`tflite_flutter`)
- **Camera** (`camera` plugin)
- **Image Processing** (`image` package)
- **Path provider** (`path_provider`)
- **Material 3** (Design moderno)

---

## Estrutura do Projeto
```
lib/
├── main.dart                     → Tela principal com câmera e UI
├── services/
│   └── classifier_service.dart   → Modelo TFLite + Data Augmentation + Votação
assets/
├── model.tflite                  → Modelo treinado (256x256, NCHW, float32)
└── labels.txt                    → Classes: Duro, Mole, RioZona, etc.
```

---

## Como Rodar

### 1. *Clone o repositório*
```bash
git clone https://github.com/acJoaog/CoffeClassApp.git
cd CoffeClassApp/Flutter/coffe_class
```

### 2. *Instale as dependências*
```bash
flutter pub get
```

### 3. *Adicione os assets*
Certifique-se de que:
- assets/model.tflite
- assets/labels.txt

estão na pasta assets/ e declarados no pubspec.yaml:
```bash
flutter:
  assets:
    - assets/model.tflite
    - assets/labels.txt
```

### 4. *Rode o app*
```bash
flutter run
```

### 5. *Build do APK*
```bash
flutter build apk --release
```
- Arquivo gerado:

```
build/app/outputs/flutter-apk/app-release.apk
```

---
