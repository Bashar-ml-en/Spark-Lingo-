# ---------- Stage 1: Build the Flutter web assets ----------
FROM cirrusci/flutter:stable AS builder

WORKDIR /app
COPY . .
# Install dependencies and build the web bundle
RUN flutter pub get && flutter build web --release

# ---------- Stage 2: Serve the compiled assets ----------
FROM nginx:alpine
# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*
# Copy the Flutter web output into nginx's webroot
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
