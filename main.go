package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"

	"cloud.google.com/go/storage"
	"github.com/go-chi/chi/middleware"
	"github.com/go-chi/chi/v5"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

var bucketName string = os.Getenv("BUCKET_NAME")

func main() {

	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Get("/*", func(w http.ResponseWriter, r *http.Request) {
		objectName := chi.URLParam(r, "*")

		// Create a new GCS client.
		ctx := context.Background()
		client, err := storage.NewClient(ctx)
		if err != nil {
			http.Error(w, "Failed to create GCS client", http.StatusInternalServerError)
			return
		}
		defer client.Close()

		// Get a handle to the GCS object.
		bucket := client.Bucket(bucketName)
		obj := bucket.Object(objectName)

		// Create a reader for the object.
		reader, err := obj.NewReader(ctx)
		if err != nil {
			if err == storage.ErrObjectNotExist {
				http.Error(w, "Object not found", http.StatusNotFound)
				return
			}
			http.Error(w, "Failed to read object", http.StatusInternalServerError)
			return
		}
		defer reader.Close()

		// Get the object's content type.
		attrs, err := obj.Attrs(ctx)
		if err != nil {
			http.Error(w, "Failed to get object attributes", http.StatusInternalServerError)
			return
		}
		contentType := attrs.ContentType

		// Set the response headers.
		w.Header().Set("Content-Type", contentType)
		w.Header().Set("Content-Disposition", "inline; filename=\""+objectName+"\"")

		// Copy the object's contents to the response writer.
		if _, err := io.Copy(w, reader); err != nil {
			http.Error(w, "Failed to copy object contents", http.StatusInternalServerError)
			return
		}
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// HTTP/2 config
	h2Handler := h2c.NewHandler(r, &http2.Server{})
	server := &http.Server{
		Addr:    ":" + port,
		Handler: h2Handler,
	}
	if err := server.ListenAndServe(); err != nil {
		fmt.Printf("Cannot start server: %s\n", err)
	}

}
