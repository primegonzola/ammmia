FROM node:14
# ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY ["package*.json", "npm-shrinkwrap.json*", "./"]
# RUN npm install && npm run build && mv node_modules ../
COPY . .
EXPOSE 3000
RUN npm install && npm run build
CMD ["npm", "start"]
