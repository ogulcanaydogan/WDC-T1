FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --fund=false
COPY . .
RUN npm run build && \
    if [ -d build ]; then mv build /out; elif [ -d dist ]; then mv dist /out; else exit 1; fi

FROM nginx:alpine
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /out /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/healthz || exit 1
