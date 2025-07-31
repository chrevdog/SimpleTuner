# SimpleTuner Docker

A Docker container for [SimpleTuner](https://github.com/bghira/SimpleTuner), a general fine-tuning kit for diffusion models. This repository provides a pre-configured environment for training Stable Diffusion, SDXL, Flux, and other diffusion models.

## Quick Start

### Prerequisites

- Docker installed on your system
- Git installed on your system
- Basic familiarity with command line operations
- GPU with at least 8GB VRAM (16GB+ recommended)

### First Time Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/chrevdog/SimpleTuner.git
   cd SimpleTuner
   ```

2. **Set up the upstream connection (one-time setup):**
   ```bash
   git remote add upstream https://github.com/bghira/SimpleTuner.git
   ```

3. **Build the Docker image:**
   ```bash
   docker build -t theloupedevteam/simpletuner-docker:latest .
   ```

4. **Run the container:**
   ```bash
   docker run -it --gpus all -p 8888:8888 -v $(pwd)/storage:/workspace/storage theloupedevteam/simpletuner-docker:latest
   ```

5. **Access JupyterLab:**
   - Open your browser and go to `http://localhost:8888`
   - No password or token required

## Updating SimpleTuner

When you want to update to the latest version of SimpleTuner:

### 1. Fetch Latest Changes

```bash
# Fetch the latest changes from upstream
git fetch upstream

# Switch to main branch
git checkout main

# Merge the latest changes
git merge upstream/main
```

### 2. Update the SimpleTuner Submodule

```bash
# Navigate to the SimpleTuner directory
cd SimpleTuner

# Pull the latest changes
git pull origin main

# Go back to the root directory
cd ..
```

### 3. Rebuild the Docker Image

```bash
# Build with the new version
docker build -t theloupedevteam/simpletuner-docker:latest .

# Tag with version number (optional but recommended)
docker tag theloupedevteam/simpletuner-docker:latest theloupedevteam/simpletuner-docker:v2.1.2
```

### 4. Push to Docker Hub

```bash
# Login to Docker Hub (if not already logged in)
docker login

# Push the latest version
docker push theloupedevteam/simpletuner-docker:latest

# Push the versioned tag
docker push theloupedevteam/simpletuner-docker:v2.1.2
```

### 5. Commit and Push Changes

```bash
# Add all changes
git add .

# Commit with a descriptive message
git commit -m "Update SimpleTuner to v2.1.2"

# Push to your repository
git push origin main
```

## Training Configuration

### Basic Training Command

### Minimum Requirements

- **RAM:** 24 min, aim for 48 GB system RAM

## Troubleshooting

### Common Issues

1. **Out of Memory (OOM) Errors:**
   - Reduce batch size: `--train_batch_size 1`
   - Use LoRA: `--use_lora`
   - Enable mixed precision: `--mixed_precision "fp16"`
   - Use gradient accumulation: `--gradient_accumulation_steps 4`

2. **Slow Training:**
   - Increase batch size if memory allows
   - Use `--mixed_precision "fp16"`
   - Consider using multiple GPUs with DeepSpeed

3. **Poor Training Results:**
   - Check your dataset quality and captions
   - Adjust learning rate (try 1e-4 to 1e-5)
   - Increase training steps
   - Use proper data augmentation


## Documentation

For detailed information about SimpleTuner features and capabilities, refer to:

- [SimpleTuner Documentation](https://github.com/bghira/SimpleTuner/tree/main/documentation)
- [Quickstart Guides](https://github.com/bghira/SimpleTuner/tree/main/documentation/quickstart)
- [Training Tutorials](https://github.com/bghira/SimpleTuner/blob/main/TUTORIAL.md)

## Contributing

1. Fork this repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Commit your changes: `git commit -m 'Add feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Support

For issues related to:
- **SimpleTuner functionality:** [Original SimpleTuner Issues](https://github.com/bghira/SimpleTuner/issues)
- **Docker container:** Create an issue in this repository
- **Training problems:** Check the [SimpleTuner Documentation](https://github.com/bghira/SimpleTuner/tree/main/documentation) 