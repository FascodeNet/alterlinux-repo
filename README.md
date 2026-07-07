# Alter Linux Repository

`alterlinux-repo`はPKGBUILDと、それをビルドするシェルスクリプトを含んだリポジトリです。

<p>
    <a href="https://github.com/FascodeNet/alterlinux-repo/actions/workflows/build.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/FascodeNet/alterlinux-repo/build.yml?branch=master&style=flat-square">
    </a>
    <a href="/LICENSE-MIT-SUSHI.md">
        <img src="https://img.shields.io/badge/license-MIT--SUSHI-orange?style=flat-square">
    </a>
    <a href="https://github.com/FascodeNet/alterlinux-repo/stargazers">
        <img src="https://img.shields.io/github/stars/FascodeNet/alterlinux-repo?color=yellow&style=flat-square&logo=github">
    </a>
    <a href="https://github.com/FascodeNet/alterlinux-repo/commits/">
        <img src="https://img.shields.io/github/last-commit/FascodeNet/alterlinux-repo?style=flat-square">
    </a>
    <a href="https://github.com/FascodeNet/alterlinux-repo/">
        <img src="https://img.shields.io/github/repo-size/FascodeNet/alterlinux-repo?style=flat-square">
    </a>
</p>

## リポジトリの追加

`/etc/pacman.conf` に以下を追記すると利用できます。

```ini
[alterlinux]
SigLevel = Optional TrustAll
Server = https://alter.repo.hayao0819.com/repo/alterlinux/x86_64
```
