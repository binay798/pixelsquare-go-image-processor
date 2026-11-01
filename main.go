package main

import (
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/h2non/bimg"
)

const TEMP_FOLDER  = "/tmp"

func heavyTask() {
	for i:=0; i < 10000000; i++ {
		fmt.Println(i)
	}
}

func main() {
	app := fiber.New(fiber.Config{
        BodyLimit: 50 * 1024 * 1024, 
    })

	app.Get("/", func(c *fiber.Ctx) error {
		go heavyTask()
		return c.SendString("Hello, World!")
	})

	app.Post("/process-image", func(c *fiber.Ctx) error {
		fileHeader, err := c.FormFile("image")
		if err != nil {
			return err
		}
		file, _ := fileHeader.Open()
		defer file.Close()
		buffer := make([]byte, fileHeader.Size)
		file.Read(buffer)
		options := bimg.Options{
			Quality:       80,          // Sweet spot between size and artifacts
			Type:          bimg.WEBP,    // Switching to WebP significantly reduces size
			Lossless:      false,
			StripMetadata: true,        // Removes EXIF data (GPS, camera info, etc.)
			NoProfile:     true,        // Removes ICC color profiles
			Compression:   9,           // Maximize compression effort
			Interlace:     true,
		}

		compressed, err := bimg.NewImage(buffer).Process(options)
		if err != nil {
			return c.Status(500).SendString("Compression failed")
		}

		c.Set("Content-Type", "image/jpeg")

		return c.Send(compressed)


	})

	app.Listen(":8849")
}
