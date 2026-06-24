# Mizuki 博客部署指南

## 项目概览

- **框架**: Astro 5.16 + Mizuki 主题
- **包管理**: pnpm
- **部署**: Vercel（push 到 master 自动构建）
- **GitHub**: `https://github.com/lmhstart/Mizuki.git`

## 快速发布文章

```bash
# 方式一：一键脚本
bash scripts/quick-publish.sh "你的文章.md"

# 方式二：手动三步
cp "你的文章.md" src/content/posts/xxx.md
git add src/content/posts/xxx.md && git commit -m "feat: add xxx"
git push origin master
```

## 文章 Frontmatter 规范

每篇文章 **必须** 在文件开头包含 YAML frontmatter（`---` 包裹），至少包含以下字段：

```yaml
---
title: 文章标题          # 必填
published: 2026-06-01    # 必填，YYYY-MM-DD 格式
description: 文章摘要     # 推荐填写，用于 SEO 和列表展示
tags: [标签1, 标签2]      # 推荐填写，用于搜索和分类
category: 分类名          # 推荐填写
draft: false              # true=草稿（不发布），false=发布
---
```

### 完整可选字段（来自 schema）

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | string | **必填** | 文章标题 |
| `published` | date | **必填** | 发布日期 |
| `updated` | date | 可选 | 最后更新日期 |
| `description` | string | `""` | 文章摘要 |
| `tags` | string[] | `[]` | 标签列表 |
| `category` | string | `""` | 分类 |
| `draft` | boolean | `false` | 是否草稿 |
| `pinned` | boolean | `false` | 是否置顶 |
| `author` | string | `""` | 作者 |
| `image` | string | `""` | 封面图片路径 |
| `sourceLink` | string | `""` | 原文链接 |
| `encrypted` | boolean | `false` | 是否加密 |
| `password` | string | `""` | 加密密码 |
| `permalink` | string | 可选 | 自定义永久链接 |

### 文件名规范

- 使用英文连字符命名，如 `chapter6-international-reserves.md`
- 放在 `src/content/posts/` 目录下
- 支持子目录，如 `guide/index.md`

## 常见构建问题

### 1. 缺少 Frontmatter → 构建失败
- **现象**: `InvalidContentEntryDataError: posts → xxx data does not match collection schema`
- **原因**: `.md` 文件缺少 YAML frontmatter，无法通过 Zod schema 校验
- **修复**: 添加 frontmatter（至少包含 `title` 和 `published`）

### 2. 原生模块编译失败（ttf2woff2）
- **现象**: `gyp ERR! configure error` 在 Vercel 构建时
- **原因**: Node v24 与 `ttf2woff2` 不兼容
- **修复**: build 命令已改为 `(node scripts/compress-fonts.js || true)`，字体压缩失败不阻塞构建

### 3. 代码块语言不支持
- **现象**: `The language could not be found. Using "txt" instead`
- **影响**: 仅影响代码高亮，不影响构建
- **解决**: 在 `astro.config.mjs` 的 expressiveCode 配置中添加 `langs` 选项

### 4. Git Push 网络问题
- **现象**: `Recv failure: Connection was reset`
- **解决**: 开启全局代理/梯子后再 push

## 构建与部署流程

```
pnpm build
  ├── astro build          → 生成 dist/ 静态文件
  ├── pagefind --site dist → 构建搜索索引
  └── node scripts/compress-fonts.js || true  → 字体压缩（可选）
```

Vercel 监听 master 分支，push 后自动触发上述构建流程。

## 文件命名对照

| 原始文件 | 发布文件名 |
|----------|-----------|
| `第六章_国际储备学习笔记.md` | `chapter6-international-reserves.md` |
| `R_data_analysis_report_1.md` | `R_data_analysis_report_1.md` |
| `R_tidyverse_tutorial.md` | `R_tidyverse_tutorial.md` |
