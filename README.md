# VoiceScribe - App de Transcrição de Áudio 🎙️

Um aplicativo Flutter moderno e completo para transcrição de áudio usando inteligência artificial.

## ✨ Funcionalidades

### 🎯 Principais Recursos

- **Gravação de Áudio**: Interface intuitiva com animação de ondas sonoras
- **Transcrição com IA**: Integração com APIs de reconhecimento de fala (Whisper, Google Cloud)
- **Histórico Completo**: Busca, filtros e organização de transcrições
- **Exportação Múltipla**: TXT e PDF com formatação profissional
- **Compartilhamento**: Envie transcrições para outros apps
- **Múltiplos Idiomas**: Suporte a Português, Inglês e Espanhol
- **Estatísticas**: Métricas de uso com tempo total e contagem de palavras

### 🎨 Interface

- Design moderno com Material Design 3
- Temas claro e escuro
- Animações suaves e transições elegantes
- Visualização de waveform em tempo real
- Timer de gravação em tempo real

## 🏗️ Arquitetura

```
lib/
├── config/              # Configurações do app (tema, cores)
├── models/              # Modelos de dados
├── providers/           # Gerenciamento de estado (Riverpod)
├── screens/             # Telas do aplicativo
├── services/            # Serviços (áudio, DB, transcrição, export)
├── utils/               # Utilitários
└── widgets/             # Widgets reutilizáveis
```

## 📦 Stack Tecnológica

- **Flutter** + **Dart**: Framework principal
- **Riverpod**: Gerenciamento de estado
- **SQLite** (sqflite): Banco de dados local
- **Record Plugin**: Gravação de áudio
- **Just Audio**: Reprodução de áudio
- **PDF**: Geração de documentos PDF
- **Share Plus**: Compartilhamento de arquivos
- **Permission Handler**: Gerenciamento de permissões

## 🚀 Começando

### Pré-requisitos

- Flutter SDK >= 3.11.0
- Dart SDK >= 3.11.0
- Android Studio / VS Code
- Dispositivo Android ou iOS (ou emulador)

### Instalação

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd voicescribe
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Execute o aplicativo:
```bash
flutter run
```

## 🔧 Configuração da API de Transcrição

O app funciona em modo de demonstração com transcrição simulada. Para ativar a transcrição real:

1. Obtenha uma API key (OpenAI Whisper recomendado)
2. Configure no serviço de transcrição:

```dart
TranscriptionService.instance.configure(
  apiKey: 'SUA_API_KEY',
  apiUrl: 'https://api.openai.com/v1/audio/transcriptions',
);
```

## 📱 Screenshots

### Tela Inicial
- Botão grande de gravação com animação
- Lista de transcrições recentes
- Navegação inferior intuitiva

### Tela de Gravação  
- Animação de ondas sonoras em tempo real
- Timer de duração da gravação
- Controles de pause/continuar
- Indicador visual de status

### Tela de Resultado
- Texto transcrito completo
- Edição manual do texto
- Botões de copiar, compartilhar e exportar
- Marcação de favoritos

### Tela de Histórico
- Lista completa de transcrições
- Barra de busca
- Estatísticas de uso
- Swipe para deletar

## 🎨 Personalização de Cores

No arquivo `lib/config/theme.dart`:

```dart
class AppColors {
  static const primary = Color(0xFF9C27B0);     // Roxo
  static const accent = Color(0xFFF44336);      // Vermelho (gravando)
  static const background = Color(0xFFF5F5F5); // Fundo claro
}
```

## 🌍 Idiomas Suportados

- 🇧🇷 Português (pt-BR)
- 🇺🇸 English (en-US)  
- 🇪🇸 Español (es-ES)

## 📊 Recursos Estatísticos

- Total de gravações realizadas
- Tempo total de gravação
- Contagem de palavras transcritas
- Média de palavras por gravação

## 🔐 Permissões Necessárias

### Android
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Precisamos acessar o microfone para gravar áudio</string>
```

## 🧪 Testes

Execute os testes:

```bash
flutter test
```

## 🐛 Troubleshooting

### Erro de build no Android
Verifique se o `minSdkVersion` está configurado corretamente em `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 33
}
```

### Problemas com permissões
O app solicita permissões automaticamente. Se negadas, o usuário deve habilitá-las nas configurações do dispositivo.

## 📝 Roadmap

- [ ] Integração com Google Cloud Speech-to-Text
- [ ] Modo offline com modelo TFLite
- [ ] Reconhecimento de múltiplos falantes
- [ ] Edição avançada de texto
- [ ] Sincronização em nuvem
- [ ] Tags e categorias
- [ ] Backup e restauração

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para detalhes.

## 👨‍💻 Desenvolvedor

Desenvolvido com ❤️ usando Flutter e Dart

## 📧 Contato

Em caso de dúvidas ou sugestões, abra uma issue no repositório.

---

**VoiceScribe** - Transformando áudio em texto com facilidade! 🎙️✨
