# GitHub Pages Setup for PointIQ Support Page

This guide will help you enable GitHub Pages to host the support page.

## Quick Setup

1. **Push the `docs` folder to your repository**
   ```bash
   git add docs/
   git commit -m "Add support page for GitHub Pages"
   git push
   ```

2. **Enable GitHub Pages in repository settings**
   - Go to your repository on GitHub: `https://github.com/genecai/PointIQ`
   - Click on **Settings** (in the repository navigation bar)
   - Scroll down to **Pages** in the left sidebar
   - Under **Source**, select **Deploy from a branch**
   - Choose **main** (or **master**) as the branch
   - Select **/docs** as the folder
   - Click **Save**

3. **Access your support page**
   - GitHub Pages will be available at: `https://genecai.github.io/PointIQ/`
   - It may take a few minutes for the page to be published initially

## Custom Domain (Optional)

If you want to use a custom domain:
1. Add a `CNAME` file in the `docs` folder with your domain name
2. Configure DNS settings as per GitHub Pages documentation
3. Update the domain in repository settings → Pages

## Updating the Support Page

Simply edit `docs/index.html` and push your changes. GitHub Pages will automatically rebuild and deploy within a few minutes.
