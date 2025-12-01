file="$1"
keywords="${var::contentPattern}"

if [ -z "$keywords" ] || [ -z "$file" ]; then
    exit 0
fi

for keyword in $(echo "$keywords" | tr '|' '\n' | sort); do
    if [ -f "$file" ]; then
        count=$(grep -Eoi "$keyword" "$file" 2>/dev/null | wc -l)
        echo "$file;$(basename "$file");$keyword;$count"
    fi
done