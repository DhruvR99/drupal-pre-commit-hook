# Git Pre-Commit Hook for Drupal Code Validation

This pre-commit hook helps ensure code quality by checking for:

- PHP syntax errors  
- Debugging functions (`dpm`, `print_r`, `var_dump`, etc.)  
- Drupal coding standards (using `phpcs`)  
- Merge conflict markers  

# Git Pre-Commit Hook for Drupal Code Validation

This pre-commit hook helps ensure code quality by checking for:

- PHP syntax errors  
- Debugging functions (`dpm`, `print_r`, `var_dump`, etc.)  
- Drupal coding standards (using `phpcs`)  
- Merge conflict markers  

## Implementing Git Hooks

Before you start, make sure you have these basic requirements installed:

- **Composer**  
- **Git**  
- **PHP CodeSniffer**  
- **drupal/coder:8.3.13**  

### Installation on macOS  
For macOS users, install the required tools using Homebrew and Composer:  

```sh
1. composer require drupal/coder:8.3.13

2. Copy the script to your Git hooks directory:  
   ```sh
   cp pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit