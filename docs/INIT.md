# 初始化指令（一次性）

在项目根目录执行：

```bash
chmod +x scripts/spark-init-repo.sh
./scripts/spark-init-repo.sh
```

## 推送到 GitHub

1. 在 GitHub 创建空仓库（不要勾选 README），或使用 CLI：

```bash
/opt/homebrew/bin/gh auth login
/opt/homebrew/bin/gh repo create Spark --private --source=. --remote=origin --push
git push -u origin develop
```

2. 若仓库已存在，使用远程 URL：

```bash
GITHUB_REMOTE_URL=https://github.com/YOUR_ORG/Spark.git ./scripts/spark-init-repo.sh
```

## 第二步：分支保护

见 [GITHUB_BRANCH_PROTECTION.md](./GITHUB_BRANCH_PROTECTION.md)。

## 日常开发

```bash
git checkout develop && git pull
git checkout -b feature/42-onboarding-animation
# 开发完成后开 PR，Squash merge 到 develop
```
