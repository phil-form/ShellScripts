files=$(ls .)

for file in $files
do
  echo "backing up $file"
  if [ -f "$file.1" ]; then
    mv "$file.1" "$file.2"
  fi
  cp "$file" "$file.1"
done