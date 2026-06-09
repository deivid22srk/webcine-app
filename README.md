# CineVS - Aplicativo Flutter Premium (Nativo)

Este repositório contém o código-fonte do aplicativo nativo Android construído em Flutter para se conectar diretamente à API do **CineVS** (`https://webcinevs2.com/api`).

## Diferenciais
- **Sem Dependência de Proxy**: O aplicativo faz todas as requisições, autenticação, busca e descriptografia/resolução das URLs de streaming diretamente no dispositivo do usuário, eliminando a necessidade de rodar o servidor proxy Node.js localmente.
- **Aparência Dark Premium**: Layout moderno com efeitos de vidro (glassmorphism), gradientes vibrantes e ícones modernos (Lucide Icons).
- **Configuração da API**: Caso o CineVS altere seu domínio no futuro, você pode atualizar a URL base da API nas configurações da tela de login.
- **Sessão por Token**: Permite autenticar usando o Token de Acesso do CineVS.
- **Seleção de Perfis com PIN**: Grade de perfis do usuário, com modal de senha numérica e atalho de preenchimento ("Usar PIN (0520)").
- **Catálogo Completo**: Abas para Filmes, Séries, Animes e barra de pesquisa integrada.
- **Filtros Avançados**: Filtre por gênero, ano e ordene por recentes, mais vistos ou avaliação da comunidade.
- **Player de Vídeo Customizado**:
  - Força tela cheia em modo paisagem automaticamente.
  - Controles customizados de reprodução, avanço/retrocesso rápido de 10s e barra de progresso.
  - Seleção de velocidade de reprodução (0.5x até 2.0x).
  - Ocultação inteligente de controles após inatividade.

## Compilação Automática do APK (GitHub Actions)

Este repositório possui uma action configurada no GitHub Actions (`build.yml`). Sempre que você enviar um commit para a branch `main` no GitHub, o servidor de CI do GitHub compilará o APK final automaticamente e o disponibilizará para download nos **Artifacts** do build!

## Compilação Local

Se preferir compilar localmente em sua máquina:

1. Instale o [Flutter SDK](https://flutter.dev/docs/get-started/install).
2. Obtenha as dependências:
   ```bash
   flutter pub get
   ```
3. Compile o APK em modo de produção:
   ```bash
   flutter build apk --release
   ```
   O APK gerado estará localizado em `build/app/outputs/flutter-apk/app-release.apk`.
