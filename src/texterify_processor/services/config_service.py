"""Service for handling configuration loading and management."""

import json
from pathlib import Path
from typing import Optional

from ..models.config import ProcessingConfig
from ..utils.console_output import ConsoleOutput


class ConfigService:
    """Service for loading and managing configuration."""
    
    @staticmethod
    def load_config(config_path: Optional[str] = None) -> ProcessingConfig:
        """Load configuration from file or return default."""
        if config_path is None:
            # Use default config path relative to the package
            package_root = Path(__file__).parent.parent.parent.parent
            config_path = package_root / "config" / "language_mappings.json"
        else:
            config_path = Path(config_path)
        
        try:
            return ConfigService._load_from_file(config_path)
        except Exception as e:
            ConsoleOutput.print_warning(f"Could not load configuration from {config_path}: {e}")
            ConsoleOutput.print_info("Using default configuration")
            return ProcessingConfig.get_default()
    
    @staticmethod
    def _load_from_file(config_path: Path) -> ProcessingConfig:
        """Load configuration from a specific file."""
        if not config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_path}")
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            ConsoleOutput.print_info(f"Loaded configuration from: {config_path.name}")
            return ProcessingConfig.from_dict(data)
            
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in configuration file: {e}")
        except Exception as e:
            raise RuntimeError(f"Error reading configuration file: {e}")
    
    @staticmethod
    def validate_config(config: ProcessingConfig) -> bool:
        """Validate configuration object."""
        if not config.language_mappings:
            return False
        
        # Validate that all mappings have non-empty strings
        for key, value in config.language_mappings.items():
            if not isinstance(key, str) or not isinstance(value, str):
                return False
            if not key.strip() or not value.strip():
                return False
        
        return True
