import os
import logging
import json
import re
from pathlib import Path
from datetime import datetime
import anthropic

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class Lich5DocumentationGenerator:
    def __init__(self, input_file=None, input_dir=None):
        """
        Initialize the Lich5 documentation generator
        
        Args:
            input_file: Single file to document
            input_dir: Directory of files to document
        """
        # Base directories
        self.input_file = Path(input_file) if input_file else None
        self.input_dir = Path(input_dir) if input_dir else None
        self.script_dir = Path(__file__).parent
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Create output directories
        self.output_dir = self.script_dir / 'documentation' / self.timestamp
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Set up file paths
        self.raw_docs_path = self.output_dir / 'raw_documentation.json'
        
        # Initialize anthropic client
        self.client = anthropic.Anthropic()
        
        # Initialize documentation storage
        self.documentation = {}
        
        logging.info(f"Initialized Lich5DocumentationGenerator:")
        logging.info(f"- Input file: {self.input_file}")
        logging.info(f"- Input directory: {self.input_dir}")
        logging.info(f"- Output directory: {self.output_dir}")

    def _write_documentation(self):
        """Write documentation to JSON file"""
        with open(self.raw_docs_path, 'w') as f:
            json.dump(self.documentation, f, indent=4)

    def _read_documentation(self):
        """Read current documentation from JSON file"""
        if not self.raw_docs_path.exists():
            return {}
        with open(self.raw_docs_path, 'r') as f:
            return json.load(f)

    def _get_language_from_extension(self, file_path):
        """Determine language based on file extension"""
        extension = Path(file_path).suffix.lower()
        if extension in ['.rb']:
            return 'ruby'
        elif extension in ['.py']:
            return 'python'
        elif extension in ['.js', '.mjs']:
            return 'javascript'
        else:
            return 'unknown'

    def analyze_file(self, file_path, chunk_content=None):
        """
        Analyze a single file or chunk of code and generate YARD-compatible docs.

        Args:
            file_path: Path to the file
            chunk_content: Optional string content instead of reading from disk
        """
        rel_path = Path(file_path).name
        logging.info(f"Analyzing file: {rel_path}")

        try:
            # Load code
            if chunk_content is not None:
                content = chunk_content
            else:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()

            # Build prompt
            prompt = self._create_ruby_prompt(rel_path, content)

            # Send to Claude
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4000,
                temperature=0,
                system="You are an expert code documentation specialist who can analyze source code and create detailed API documentation with examples.",
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )

            raw_doc = message.content[0].text

            # Store into our dict
            self.documentation[rel_path] = {
                'raw_doc': raw_doc,
                'api_doc': self._extract_api_documentation(raw_doc, 'ruby'),
                'original_code': content
            }

            # Persist to disk
            self._write_documentation()

            logging.info(f"Completed analysis of file: {rel_path}")
            return raw_doc

        except Exception as e:
            logging.error(f"Error analyzing file {file_path}: {e}", exc_info=True)
            return None

    def _create_ruby_prompt(self, file_name, content):
        """Create a specialized prompt for Ruby files with YARD format focus"""
        return f"""Analyze this Ruby file from the Lich5 project: {file_name}

```ruby
{content}
```

Generate detailed YARD-compatible documentation for all classes, modules, methods, and constants.

For each method:
1. Purpose and behavior
2. All parameters with types and descriptions
3. Return value with type and description
4. Any exceptions or errors that might be raised
5. Example usage with code snippet
6. Any important notes or caveats

Use the YARD format for documentation, which looks like:
```ruby
# Description of what the method does.
#
# @param param_name [Type] description of the parameter
# @return [Type] description of the return value
# @raise [ErrorType] description of when this error occurs
# @example
#   example_code_here
#
# @note Any additional information
```

VERY IMPORTANT: Only provide the documentation comments WITHOUT duplicating the original code. Do not include any Ruby code, only provide YARD-formatted documentation comments.

Format your response like this, with just the documentation comments:
```
# Module/class description
#
# @author Lich5 Documentation Generator

# Method description
#
# @param [Type] parameter_name Parameter description
# @return [Type] Return value description
# ...
```

Ensure completeness - document ALL public methods and attributes.
"""

    def _create_generic_prompt(self, file_name, content, language):
        """Create a prompt for other programming languages"""
        return f"""Analyze this {language} file from the Lich5 project: {file_name}

```{language}
{content}
```

Generate detailed documentation for all classes, modules, methods, functions, and constants.

For each function/method:
1. Purpose and behavior
2. All parameters with types and descriptions
3. Return value with type and description
4. Any exceptions or errors that might be raised
5. Example usage with code snippet
6. Any important notes or caveats

Use a standard documentation format appropriate for {language}.

VERY IMPORTANT: Only provide the documentation comments WITHOUT duplicating the original code.

Ensure completeness - document ALL public methods and attributes.
"""

    def _extract_api_documentation(self, raw_doc, language):
        """Extract structured API documentation from the raw output"""
        # This could be enhanced with more sophisticated parsing
        # For now, return the raw doc as structured content
        return {
            'language': language,
            'documentation': raw_doc
        }

    def process_directory(self):
        """Process all files in the input directory"""
        if not self.input_dir:
            logging.error("No input directory specified")
            return

        logging.info(f"Processing directory: {self.input_dir}")
        
        # Get all files in directory recursively
        for file_path in sorted(Path(self.input_dir).glob('**/*')):
            if file_path.is_file() and file_path.suffix.lower() in ['.rb', '.py', '.js', '.mjs']:
                self.analyze_file(file_path)

    def process_file(self):
        """Process the single input file"""
        if not self.input_file:
            logging.error("No input file specified")
            return

        if not self.input_file.exists():
            logging.error(f"Input file does not exist: {self.input_file}")
            return

        logging.info(f"Processing file: {self.input_file}")
        self.analyze_file(self.input_file)

    def process_chunk(self, chunk_content, file_name=None):
        """Process a chunk of code without a full file"""
        if not chunk_content:
            logging.error("No chunk content provided")
            return

        if not file_name:
            file_name = f"chunk_{self.timestamp}.rb"  # Default to Ruby
            
        logging.info(f"Processing code chunk as: {file_name}")
        return self.analyze_file(file_name, chunk_content)

    def generate_documentation(self, output_format='yard'):
        """Generate final documentation in desired format"""
        logging.info(f"Generating documentation in {output_format} format...")
        
        # Read the collected documentation
        self.documentation = self._read_documentation()
        
        if output_format.lower() == 'yard':
            return self._generate_yard_docs()
        elif output_format.lower() == 'markdown':
            return self._generate_markdown_docs()
        elif output_format.lower() == 'annotated':
            return self._generate_annotated_code()
        else:
            logging.error(f"Unsupported output format: {output_format}")
            return None

    def _generate_yard_docs(self):
        """Generate YARD documentation files"""
        yard_dir = self.output_dir / 'yard'
        yard_dir.mkdir(exist_ok=True)
        
        for file_name, doc_data in self.documentation.items():
            # For YARD, we want to generate documentation comments only
            if doc_data.get('api_doc', {}).get('language') == 'ruby':
                output_path = yard_dir / f"{file_name}.yard"
                
                # Extract yard documentation - strip any code blocks and just keep comments
                doc_content = doc_data['raw_doc']
                
                # Clean up the documentation to remove any actual Ruby code
                # This keeps just the comments for YARD
                clean_doc = self._clean_yard_documentation(doc_content)
                
                with open(output_path, 'w') as f:
                    f.write(clean_doc)
                
                logging.info(f"Generated YARD documentation: {output_path}")
        
        return yard_dir

    def _clean_yard_documentation(self, doc_content):
        """Remove Ruby code and keep only YARD comments"""
        # Use regex to find code blocks and remove them
        doc_content = re.sub(r'```ruby.*?```', '', doc_content, flags=re.DOTALL)
        
        # Remove any line that doesn't start with a comment
        lines = doc_content.split('\n')
        comment_lines = []
        in_comment_block = False
        
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('#'):
                comment_lines.append(line)
                in_comment_block = True
            elif stripped == '' and in_comment_block:
                comment_lines.append(line)  # Keep empty lines within comment blocks
            elif stripped.startswith('```') or stripped.startswith('`'):
                # Skip code blocks markers
                continue
            else:
                in_comment_block = False
        
        return '\n'.join(comment_lines)

    def _generate_annotated_code(self):
        """Generate annotated code files with documentation inserted as comments"""
        annotated_dir = self.output_dir / 'annotated'
        annotated_dir.mkdir(exist_ok=True)
        
        for file_name, doc_data in self.documentation.items():
            original_code = doc_data.get('original_code', '')
            
            if not original_code:
                continue
                
            # Use a second API call to merge documentation with code
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=8000,
                temperature=0,
                system="You are an expert documentation specialist. Your task is to insert appropriate documentation comments into existing code.",
                messages=[{
                    "role": "user",
                    "content": f"""
I have the following code file and separately generated documentation for it.

Original code:
```
{original_code}
```

Documentation (YARD format for Ruby):
```
{doc_data['raw_doc']}
```

Please create a new version of the code file with the documentation inserted at the appropriate places. 
For Ruby files, use YARD format comments directly above each method, class, module, or constant being documented.
Ensure you:
1. Don't modify the actual code logic
2. Place each documentation comment directly above the relevant code element
3. Maintain proper indentation for the comments
4. Include all the original code

Return just the fully annotated code file.
"""
                }]
            )
            
            annotated_code = message.content[0].text
            
            # Clean up the response to extract just the code
            clean_code = self._extract_code_from_response(annotated_code)
            
            output_path = annotated_dir / file_name
            with open(output_path, 'w') as f:
                f.write(clean_code)
            
            logging.info(f"Generated annotated code: {output_path}")
        
        return annotated_dir

    def _extract_code_from_response(self, response):
        """Extract clean code from an LLM response"""
        # Try to find code blocks first
        code_blocks = re.findall(r'```(?:ruby|python|javascript)?\s*(.*?)```', response, re.DOTALL)
        
        if code_blocks:
            return code_blocks[0].strip()
        
        # If no code blocks, try to clean up the whole response
        lines = response.split('\n')
        clean_lines = []
        capture = False
        
        for line in lines:
            if '```' in line and not capture:
                capture = True
                continue
            elif '```' in line and capture:
                capture = False
                continue
            
            if capture or not line.strip().startswith(('Here', 'This', 'I', 'The')):
                clean_lines.append(line)
        
        return '\n'.join(clean_lines).strip()

    def _generate_markdown_docs(self):
        """Generate Markdown documentation files"""
        md_dir = self.output_dir / 'markdown'
        md_dir.mkdir(exist_ok=True)
        
        # Generate individual MD files
        for file_name, doc_data in self.documentation.items():
            output_path = md_dir / f"{file_name}.md"
            
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4000,
                temperature=0,
                system="You are a technical writer who creates clear, well-organized API documentation.",
                messages=[{
                    "role": "user",
                    "content": f"""
Convert the following raw API documentation into clean, well-formatted Markdown:

{doc_data['raw_doc']}

Format it as a proper Markdown document with:
1. Clear headings and structure
2. Code blocks with syntax highlighting 
3. Tables for parameters and return values where appropriate
4. Consistent formatting throughout
"""
                }]
            )
            
            with open(output_path, 'w') as f:
                f.write(message.content[0].text)
            
            logging.info(f"Generated Markdown documentation: {output_path}")
        
        # Generate index file
        index_path = md_dir / "index.md"
        with open(index_path, 'w') as f:
            f.write("# Lich5 API Documentation\n\n")
            f.write("## Files\n\n")
            for file_name in sorted(self.documentation.keys()):
                f.write(f"* [{file_name}]({file_name}.md)\n")
        
        return md_dir

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate documentation for Lich5')
    parser.add_argument('--file', help='Single file to document', default=None)
    parser.add_argument('--dir', help='Directory of files to document', default=None)
    parser.add_argument('--chunk', help='Document a code chunk from stdin', action='store_true')
    parser.add_argument('--format', help='Output format (yard, markdown, or annotated)', default='yard')
    parser.add_argument('--build-only', help='Skip analysis; rebuild docs from existing raw_documentation.json', action='store_true')
    parser.add_argument('--cache-dir', help='Directory containing raw_documentation.json from a previous run', default=None)
    
    args = parser.parse_args()

    generator = Lich5DocumentationGenerator(input_file=args.file, input_dir=args.dir)

    if args.cache_dir:
        cache = Path(args.cache_dir)
        if not cache.exists() or not (cache / 'raw_documentation.json').exists():
            logging.error(f"Cache directory {cache} does not contain raw_documentation.json")
            return
        generator.output_dir    = cache
        generator.raw_docs_path = cache / 'raw_documentation.json'

    if args.build_only:
        # Rebuild documentation files from existing cache
        output_dir = generator.generate_documentation(args.format)
        logging.info(f"Documentation rebuilt from cache at: {output_dir}")
        return
    
    if args.chunk:
        import sys
        print("Enter or paste code chunk (Ctrl+D to finish on Unix, Ctrl+Z followed by Enter on Windows):")
        chunk_content = sys.stdin.read()
        generator = Lich5DocumentationGenerator()
        doc = generator.process_chunk(chunk_content)
        print("\nGenerated Documentation:")
        print(doc)
    
    elif args.file or args.dir:
        
        if args.file:
            generator.process_file()
        elif args.dir:
            generator.process_directory()
            
        output_dir = generator.generate_documentation(args.format)
        logging.info(f"Documentation generated in: {output_dir}")
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
