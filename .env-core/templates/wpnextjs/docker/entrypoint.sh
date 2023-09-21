#!/bin/sh

# Installs all packages if required by Make
if [ "$1" = "install" ]; then
    npm install
else
    npx create-next-app@latest . --use-npm --example "https://github.com/vercel/next-learn/tree/master/basics/learn-starter"
fi

cd /usr/src/app
npm run dev
