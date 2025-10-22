#!/bin/bash
# Script to help set up DeepL API key in all environments

echo "🔑 DeepL API Key Setup Helper"
echo "=============================="
echo ""
echo "Enter your DeepL API key:"
read -r DEEPL_KEY

if [ -z "$DEEPL_KEY" ]; then
    echo "❌ No API key provided. Exiting."
    exit 1
fi

echo ""
echo "This will add 'deepl_api_key: $DEEPL_KEY' to credentials."
echo ""
echo "Select environments to configure:"
echo "1) Development only"
echo "2) Production only"
echo "3) All environments (development, production, staging, test)"
echo "4) Custom selection"
read -r choice

case $choice in
    1)
        envs=("development")
        ;;
    2)
        envs=("production")
        ;;
    3)
        envs=("development" "production" "staging" "test")
        ;;
    4)
        echo "Enter environments (space-separated, e.g., 'development production'):"
        read -r custom_envs
        IFS=' ' read -ra envs <<< "$custom_envs"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "📝 Instructions for each environment:"
echo "======================================"

for env in "${envs[@]}"; do
    echo ""
    echo "For $env environment:"
    if [ "$env" = "development" ]; then
        echo "  Run: EDITOR=\"code --wait\" bin/rails credentials:edit"
    else
        echo "  Run: EDITOR=\"code --wait\" bin/rails credentials:edit --environment $env"
    fi
    echo "  Add this line:"
    echo "    deepl_api_key: $DEEPL_KEY"
    echo "  Save and close the file."
    echo ""
    echo "  Press Enter when ready to continue..."
    read -r
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "🧪 Test your configuration:"
echo "  bin/rails runner \"puts DeeplClient.new.usage\""
