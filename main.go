package main

import (
	"github.com/gofiber/fiber/v2"
	"github.com/h2non/bimg"
)

const TEMP_FOLDER  = "/tmp"

func main() {
	app := fiber.New(fiber.Config{
        BodyLimit: 50 * 1024 * 1024, 
    })

	app.Get("/", func(c *fiber.Ctx) error {
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
					Quality:       75,
					Type:          bimg.JPEG,
					StripMetadata: true,
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
