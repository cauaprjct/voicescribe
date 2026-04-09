# 🚀 Como Publicar no GitHub

## Passo 1: Criar repositório no GitHub

1. Acesse https://github.com/new
2. Nome: `voicescribe`
3. Descrição: `🎙️ App de transcrição de áudio com IA - Flutter`
4. Público
5. NÃO marque "Add README" (já temos)
6. Criar repositório

## Passo 2: Comandos Git

Execute na pasta `voicescribe`:

```bash
# Inicializar git (se ainda não foi)
git init

# Adicionar todos os arquivos
git add .

# Primeiro commit
git commit -m "🎙️ Initial commit - VoiceScribe app completo"

# Adicionar remote (SUBSTITUA SEU_USERNAME)
git remote add origin https://github.com/SEU_USERNAME/voicescribe.git

# Enviar para GitHub
git branch -M main
git push -u origin main
```

## Passo 3: Adicionar screenshots

1. Crie uma pasta `screenshots` no repositório
2. Adicione as imagens
3. Commit e push:

```bash
git add screenshots/
git commit -m "📸 Add app screenshots"
git push
```

## Passo 4: Atualizar README com screenshots

Adicione no README.md:

```markdown
## 📸 Screenshots

<p align="center">
  <img src="screenshots/home.png" width="200" />
  <img src="screenshots/recording.png" width="200" />
  <img src="screenshots/result.png" width="200" />
  <img src="screenshots/history.png" width="200" />
</p>
```

---

✅ Pronto! Seu projeto estará no GitHub!
