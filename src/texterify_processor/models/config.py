"""Configuration models for the Texterify Language Processor."""

from dataclasses import dataclass, field
from typing import Dict, Optional
from pathlib import Path


@dataclass
class OutputFormat:
    """Output format configuration."""
    date_format: str = "%d_%m"
    base_filename: str = "lang_files"
    extension: str = ".zip"


@dataclass
class ProcessingConfig:
    """Configuration for processing Texterify exports."""
    language_mappings: Dict[str, str] = field(default_factory=dict)
    case_sensitive: bool = False
    preserve_extensions: bool = False
    backup_original: bool = False
    output_format: OutputFormat = field(default_factory=OutputFormat)
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'ProcessingConfig':
        """Create ProcessingConfig from dictionary."""
        output_format_data = data.get('settings', {}).get('output_format', {})
        output_format = OutputFormat(
            date_format=output_format_data.get('date_format', '%d_%m'),
            base_filename=output_format_data.get('base_filename', 'lang_files'),
            extension=output_format_data.get('extension', '.zip')
        )
        
        settings = data.get('settings', {})
        
        return cls(
            language_mappings=data.get('language_mappings', {}),
            case_sensitive=settings.get('case_sensitive', False),
            preserve_extensions=settings.get('preserve_extensions', False),
            backup_original=settings.get('backup_original', False),
            output_format=output_format
        )
    
    @classmethod
    def get_default(cls) -> 'ProcessingConfig':
        """Get default configuration."""
        return cls(
            language_mappings={
                "en": "24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json",
                "tr": "26c7ace9-13fc-43b8-9988-2384fe670d03.json"
            },
            case_sensitive=False,
            preserve_extensions=False,
            backup_original=False,
            output_format=OutputFormat()
        )
