# Coffee Class – Classificador de Grãos de Café com IA

**Coffee Class** é um aplicativo Flutter que utiliza **inteligência artificial (TensorFlow Lite)** para classificar grãos de café em tempo real com a câmera do celular.  
Desenvolvido para **produtores, baristas e entusiastas do café**, o app identifica automaticamente os tipos de grãos com **alta precisão e robustez** graças a **data augmentation e votação ponderada**.

---

📦[Baixar APK](https://github.com/acJoaog/CoffeClassApp/releases/download/v1.5/coffe_class.apk)

## Funcionalidades

- **Captura automática de 3 fotos** com intervalo de 0.5s  
- **Data Augmentation em tempo real**:  
  Para cada foto capturada, gera **2 versões aumentadas** → **9 imagens no total**  
- **Transformações aplicadas**:
  - `A`: Flip Horizontal + Rotação aleatória (±15°)
  - `B`: Flip Vertical + Cisalhamento (shear) aleatório (±15°)
- **Resultado final por votação ponderada**:  
  **Frequência × Confiança Média** entre as 9 predições  
- **Botão "Nova Captura"** com animação suave  
- **Tema minimalista elegante** (Light Mode) com paleta de café  
- **Preview da câmera**  
- **Layout responsivo** (funciona em qualquer tela)  

---

## Como Funciona o Cálculo da Moda (Robust Voting)
```
[3 fotos capturadas]
↓
Cada foto → [Original + AugA + AugB] = 3 versões
↓
9 predições → Top-1 de cada uma
↓
Agrupar por rótulo → count × média(confiança)
↓
Classe com maior score é exibida
```

> **Mais robusto que moda simples**  
> Evita falsos positivos por ruído ou iluminação

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
- **Data Augmentation** (Flip, Rotate, Shear)
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

Coffee Class: Classificação de café com precisão, robustez e elegância.