# ==============================================================================
# == VARLAM EYE - DOCKERFILE v2.0
# == RE-ENGINEERED BY VARLAM FOR RAILWAY.APP
# == PRINCIPLES: SECURITY, EFFICIENCY, STABILITY. FUCKING RELIABILITY.
# ==============================================================================

# --- ЭТАП 1: "БАЗА", БЛЯТЬ. ---
# Используем, блять, официальный, сука, Node.js образ. Версия - важна.
FROM node:18-alpine as base

# Ставим, блять, минимум, сука, необходимый для сборки.
# git - потому что Rendertron-у может понадобиться для чего-то. Безопаснее иметь.
RUN apk add --no-cache git

WORKDIR /app

# --- ЭТАП 2: "ЗАВИСИМОСТИ", БЛЯТЬ. ---
# Этот, блять, слой - кэшируется. Чтобы не качать, сука, `node_modules` каждый, блять, раз.
FROM base as dependencies

# Сначала, блять, - package.json, чтобы Docker мог кэшировать, сука, этот шаг.
COPY package.json package-lock.json ./

# Ставим ТОЛЬКО, БЛЯТЬ, боевые, сука, зависимости (`--production`). Без, блять, мусора для разработки.
RUN npm install --production

# --- ЭТАП 3: "СБОРКА", БЛЯТЬ. ---
# Копируем, блять, всё остальное дерьмо - исходный код Rendertron'а.
FROM base as build

# Сначала копируем исходники
COPY . .

# Потом, блять, - уже собранные зависимости из предыдущего, блять, слоя.
COPY --from=dependencies /app/node_modules ./node_modules

# (Если бы, блять, был 'build' шаг, вроде 'npm run build', он был бы здесь. У Rendertron'а - нет.)

# --- ЭТАП 4: "БОЕВОЙ, БЛЯТЬ, КОНТЕЙНЕР". (Финальный, сука, образ) ---
# Начинаем, блять, с чистого, сука, листа. Только то, что нужно для работы.
FROM node:18-alpine

WORKDIR /app

# СОЗДАЁМ, БЛЯТЬ, ПОЛЬЗОВАТЕЛЯ-КАЛЕКУ. БЕЗ ПРАВ, СУКА.
RUN addgroup -S rendertron && adduser -S rendertron -G rendertron

# Меняем, блять, владельца папки. Забираем, блять, у 'root'а всё, нахуй.
RUN chown -R rendertron:rendertron /app

# Копируем, блять, собранное, сука, приложение из "build" слоя.
# Сразу, блять, выставляем правильного, блять, владельца.
COPY --from=build --chown=rendertron:rendertron /app .

# Переключаемся, блять, на этого, сука, "калеку". Чтобы, блять, враг, если прорвётся, - не смог, сука, нихуя.
USER rendertron

# Порт, на котором, блять, эта хуйня будет слушать.
EXPOSE 3000

# КОМАНДА, БЛЯТЬ, "ЖИТЬ, СУКА".
# src/main.js - это стандартная точка входа для Rendertron'а.
CMD ["node", "src/main.js"]

# И, БЛЯТЬ, - "ПУЛЬС". Чтобы, блять, мы знали, что он не сдох.
# Он будет, сука, дёргать endpoint '/healthz' каждые 30 секунд.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "require('http').request('http://localhost:3000/healthz', {timeout: 2000}, (res) => res.statusCode == 200 ? process.exit(0) : process.exit(1)).end()"
