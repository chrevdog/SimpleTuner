# SimpleTuner Training Configuration Guide

## Overview

This guide provides comprehensive information for configuring SimpleTuner training runs, with a focus on Flux model training. The configuration files in this directory serve as templates that should be customized for your specific training needs.

## Hardware Requirements

### System Memory
Flux requires significant **system RAM** in addition to GPU memory. Simply quantizing the model at startup requires about 50GB of system memory.

### GPU Requirements
When training every component of a rank-16 LoRA (MLP, projections, multimodal blocks), VRAM usage varies:

- **No quantization**: ~30GB VRAM
- **int8 + bf16**: ~18GB VRAM  
- **int4 + bf16**: ~13GB VRAM
- **NF4 + bf16**: ~9GB VRAM
- **int2 + bf16**: ~9GB VRAM

**Minimum Requirements:**
- **Absolute minimum**: Single 3080 10G
- **Realistic minimum**: Single 3090 or V100 GPU
- **Ideal**: Multiple 4090, A6000, L40S, or better

**Note**: Apple GPUs do not currently work for training Flux.

## Configuration Files

### 1. Main Configuration (`config.json`)

Copy `config_template.json` to `config/config.json` and customize for your training run.

#### Essential Settings

```json
{
  "model_type": "lora",
  "model_family": "flux", 
  "model_flavour": "dev",
  "pretrained_model_name_or_path": "black-forest-labs/FLUX.1-dev",
  "pretrained_vae_model_name_or_path": "black-forest-labs/FLUX.1-dev",
  "output_dir": "output/models",
  "train_batch_size": 1,
  "validation_resolution": "1024x1024",
  "validation_guidance": 3,
  "validation_num_inference_steps": 20,
  "mixed_precision": "bf16",
  "optimizer": "adamw_bf16",
  "gradient_checkpointing": true
}
```

#### Model Flavour Options
- `krea` - Default FLUX.1-Krea [dev] model (open-weights variant of Krea 1)
- `dev` - Dev model flavour (previous default)
- `schnell` - Schnell model flavour with fast training schedule
- `kontext` - Kontext training (see specific guide)
- `fluxbooru` - De-distilled model requiring CFG
- `libreflux` - De-distilled model requiring attention masking

#### Quantization Settings
For reduced VRAM usage:

```json
{
  "base_model_precision": "int8-quanto",
  "text_encoder_1_precision": "no_change", 
  "text_encoder_2_precision": "no_change",
  "lora_rank": 16,
  "max_grad_norm": 1.0,
  "base_model_default_dtype": "bf16"
}
```

#### LoRA-Specific Settings
```json
{
  "--flux_lora_target": "all",
  "--lora_init_type": "loftq"
}
```

**LoRA Target Options:**
- `mmdit` - Very stable training, slower learning
- `all` - Can shift model distribution, prone to forgetting
- `all+ffs` - All attention + feed-forward layers (may lack portability)
- `context` - Experimental choice
- `context+ffs` - Useful for pretraining new tokens
- `tiny` / `nano` - Train just 1-2 layers

#### TREAD Configuration (Optional)
For accelerated training:

```json
{
  "tread_config": {
    "routes": [
      {
        "selection_ratio": 0.5,
        "start_layer_idx": 2,
        "end_layer_idx": -2
      }
    ]
  }
}
```

### 2. LyCORIS Configuration (`lycoris_config.json`)

Copy `lycoris_config_template.json` to `config/lycoris_config.json`.

```json
{
    "algo": "lokr",
    "multiplier": 1.0,
    "linear_dim": 10000,
    "linear_alpha": 1,
    "factor": 16,
    "apply_preset": {
        "target_module": [
            "Attention",
            "FeedForward"
        ],
        "module_algo_map": {
            "Attention": {
                "factor": 16
            },
            "FeedForward": {
                "factor": 8
            }
        }
    }
}
```

**Algorithm Options:**
- `lokr` - LoKr algorithm (recommended)
- `lora` - Standard LoRA
- `oft` - Orthogonal Fine-Tuning
- `ia3` - IA³

### 3. Multi-Data Backend Configuration (`multidatabackend.json`)

Copy `multidatabackend_template.json` to `config/multidatabackend.json`.

#### Example Configuration
```json
[
  {
    "id": "dreambooth-subject",
    "type": "local",
    "crop": false,
    "resolution": 1024,
    "minimum_image_size": 1024,
    "maximum_image_size": 1024,
    "target_downsample_size": 1024,
    "resolution_type": "pixel_area",
    "cache_dir_vae": "cache/vae/flux/dreambooth-subject",
    "instance_data_dir": "datasets/dreambooth-subject",
    "caption_strategy": "instanceprompt",
    "instance_prompt": "your subject name here",
    "metadata_backend": "discovery",
    "repeats": 1000
  },
  {
    "id": "text-embeds",
    "type": "local",
    "dataset_type": "text_embeds",
    "default": true,
    "cache_dir": "cache/text/flux",
    "disabled": false,
    "write_batch_size": 128
  }
]
```

#### Key Settings Explained
- `crop_aspect`: `"square"` for consistent training
- `crop_style`: `"center"` or `"random"`
- `caption_strategy`: `"instanceprompt"` for Dreambooth, `"filename"` for regular datasets
- `repeats`: Number of times to repeat dataset (higher for smaller datasets)

### 4. User Prompt Library (`user_prompt_library.json`)

Copy `user_prompt_library_template.json` to `config/user_prompt_library.json`.

Replace `<token>` with your subject name:

```json
{
    "anime_<token>": "a breathtaking anime-style portrait of <token>, capturing her essence with vibrant colors and expressive features",
    "chef_<token>": "a high-quality, detailed photograph of <token> as a sous-chef, immersed in the art of culinary creation",
    "just_<token>": "a lifelike and intimate portrait of <token>, showcasing her unique personality and charm",
    "cinematic_<token>": "a cinematic, visually stunning photo of <token>, emphasizing her dramatic and captivating presence",
    "elegant_<token>": "an elegant and timeless portrait of <token>, exuding grace and sophistication"
}
```

**Important**: Flux is a flow-matching model. Use longer, more descriptive prompts as shorter similar prompts will produce practically identical images.

### 5. Environment Configuration (`config.env`)

Use `config.env` as-is for basic environment setup:

```bash
# Accelerate configuration settings
TRAINING_NUM_PROCESSES=1
TRAINING_NUM_MACHINES=1
MIXED_PRECISION=bf16
TRAINING_DYNAMO_BACKEND=no

# Additional optional settings
DISABLE_UPDATES=true
DISABLE_LD_OVERRIDE=false
ACCELERATE_EXTRA_ARGS="--num_cpu_threads_per_process 1"
```

## Training Parameters

### Learning Rates
- **LoRA**: Use lower learning rates (1e-5 to 1e-4) for large models
- **LoKr**: Higher learning rates work better (1e-3 with AdamW, 2e-4 with Lion)

### Gradient Accumulation
- Can be used with bf16 training (contrary to previous guidance)
- Increases runtime linearly (value of 2 = half speed, twice the time)

### Optimizers
- **Beginners**: Stick with `adamw_bf16`
- **Advanced**: `optimi-lion` and `optimi-stableadamw` are good choices

## Dataset Considerations

### Quality Requirements
⚠️ **Image quality is more important for Flux than other models** - it will absorb artifacts first, then learn the concept/subject.

### Minimum Dataset Size
- Must be larger than `train_batch_size * gradient_accumulation_steps`
- Must be larger than `vae_batch_size`
- If you see "no images detected in dataset", increase the `repeats` value

### Multi-Resolution Training
Running 512px and 1024px datasets concurrently is supported and can result in better convergence for Flux.

## Advanced Features

### Classifier-Free Guidance (CFG)
- **CFG-distilled (flux_guidance_value = 1.0)**: Preserves initial distillation, most compatible
- **CFG-trained (flux_guidance_value = 3.5-4.5)**: Reintroduces CFG objective, improves creativity

### Masked Loss Training
For training subjects or styles with masking, see the Dreambooth guide section on masked loss.

### Custom Fine-tuned Models
For models like Dev2Pro that lack full directory structure:

```json
{
    "model_family": "flux",
    "pretrained_model_name_or_path": "black-forest-labs/FLUX.1-dev",
    "pretrained_transformer_model_name_or_path": "ashen0209/Flux-Dev2Pro",
    "pretrained_vae_model_name_or_path": "black-forest-labs/FLUX.1-dev",
    "pretrained_transformer_subfolder": "none"
}
```

## Troubleshooting

### Memory Issues
- **Lowest VRAM config**: Use `nf4-bnb` precision, Lion 8Bit Paged optimizer, 512px resolution
- **Startup crashes**: Try `--quantize_via=cpu` or `--offload_during_startup=true`
- **VAE encoding issues**: Enable `--vae_enable_tiling=true`

### Training Issues
- **Model collapse**: Lower learning rate, increase `max_grad_norm`
- **Poor convergence**: Increase dataset size, adjust learning rate
- **Artifacts**: Use higher quality training data, avoid overtraining

### Quantization Notes
- **int8**: Hardware acceleration and torch.compile support on newer NVIDIA hardware
- **nf4-bnb**: Brings VRAM to 9GB, fits on 10G cards
- **Important**: Use same base model precision when loading LoRA in ComfyUI

## File Setup Instructions

1. Copy template files to `config/` directory
2. Remove "_template" from filenames
3. Customize settings for your specific training run
4. Use `config.env` as-is
5. Ensure all paths point to your actual dataset directories

## Credits

- [Terminus Research](https://huggingface.co/terminusresearch) for extensive testing and development
- [Lambda Labs](https://lambdalabs.com) for compute allocations
- [@JimmyCarter](https://huggingface.co/jimmycarter) and [@kaibioinfo](https://github.com/kaibioinfo) for contributions and testing 