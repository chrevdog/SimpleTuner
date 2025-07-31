#!/bin/bash

# SimpleTuner Docker Setup Script
# This script helps first-time users set up the SimpleTuner Docker environment

set -e

echo "🚀 SimpleTuner Docker Setup"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    print_status "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    print_error "Please run this script from the root directory of the SimpleTuner Docker project"
    exit 1
fi

print_status "Setting up SimpleTuner Docker environment..."

# Step 1: Set up upstream remote if not already set
if ! git remote | grep -q upstream; then
    print_status "Setting up upstream remote..."
    git remote add upstream https://github.com/bghira/SimpleTuner.git
    print_success "Upstream remote added"
else
    print_status "Upstream remote already configured"
fi

# Step 2: Create storage directory
print_status "Creating storage directory..."
mkdir -p storage/datasets
mkdir -p storage/config
mkdir -p storage/outputs
mkdir -p storage/models
print_success "Storage directories created"

# Step 3: Build Docker image
print_status "Building Docker image (this may take a while)..."
docker build -t theloupedevteam/simpletuner-docker:latest .

if [ $? -eq 0 ]; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Step 4: Create a sample dataset directory
print_status "Creating sample dataset structure..."
mkdir -p storage/datasets/sample_dataset
echo "# Add your training images here" > storage/datasets/sample_dataset/README.md
echo "This directory is for your training images." >> storage/datasets/sample_dataset/README.md
echo "Supported formats: JPG, PNG, WebP" >> storage/datasets/sample_dataset/README.md

# Step 5: Create a sample configuration
print_status "Creating sample configuration..."
mkdir -p storage/config
cat > storage/config/sample_training_config.json << 'EOF'
{
  "model_type": "sdxl",
  "base_model": "stabilityai/stable-diffusion-xl-base-1.0",
  "output_dir": "./outputs/sample_training",
  "train_data_dir": "./datasets/sample_dataset",
  "resolution": 1024,
  "train_batch_size": 1,
  "gradient_accumulation_steps": 4,
  "max_train_steps": 1000,
  "learning_rate": 1e-4,
  "lr_scheduler": "constant",
  "lr_warmup_steps": 100,
  "mixed_precision": "fp16",
  "save_steps": 500,
  "save_total_limit": 2
}
EOF
print_success "Sample configuration created"

# Step 6: Create a run script
print_status "Creating run script..."
cat > run_simpletuner.sh << 'EOF'
#!/bin/bash

# SimpleTuner Docker Run Script
# This script runs the SimpleTuner Docker container

echo "🚀 Starting SimpleTuner Docker container..."

# Check if GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected, using GPU acceleration"
    GPU_ARGS="--gpus all"
else
    echo "No NVIDIA GPU detected, running on CPU (not recommended for training)"
    GPU_ARGS=""
fi

# Run the container
docker run -it \
    $GPU_ARGS \
    -p 8888:8888 \
    -v $(pwd)/storage:/workspace/storage \
    theloupedevteam/simpletuner-docker:latest

echo "✅ Container stopped"
EOF

chmod +x run_simpletuner.sh
print_success "Run script created"

# Step 7: Display next steps
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Add your training images to: storage/datasets/sample_dataset/"
echo "2. Modify the configuration in: storage/config/sample_training_config.json"
echo "3. Run the container: ./run_simpletuner.sh"
echo "4. Access JupyterLab at: http://localhost:8888"
echo ""
echo "For detailed training instructions, see: TRAINING_GUIDE.md"
echo "For troubleshooting, see: README.md"
echo ""
print_success "Setup complete! 🚀" 