### Hi there 👋

<!--
**Lazerbeak12345/Lazerbeak12345** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

Here are some ideas to get you started:

- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...
-->

## How to use my dotfiles

<a href="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim"><img src="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim/badges/plugins?style=flat" /></a>
<a href="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim"><img src="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim/badges/leaderkey?style=flat" /></a>
<a href="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim"><img src="https://dotfyle.com/Lazerbeak12345/lazerbeak-config-nvim/badges/plugin-manager?style=flat" /></a>

I'm making use of an approach introduced to me by [kalkayan and their dotfiles](https://github.com/kalkayan/dotfiles).

```bash
git clone --bare https://github.com/Lazerbeak12345/Lazerbeak12345 $HOME/.dotfiles

# then put this in your .bashrc

alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

# refresh your bash instance, then use the dotfiles command to restore the .gitignore and any other files you'd like to try out.
# be sure to make backups!
```

There's a lot of reasons why this approach is awesome, and perhaps the biggest one is its simplicity.

