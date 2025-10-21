import json
import os
import pathlib
import subprocess
import tempfile
from datetime import datetime

from m_base import Base


class Cc(Base):
    def process_prompts(self, prompt_file="prompts.jsonl", output_dir=None):
        """
        Process prompts from a JSONL file and run Claude commands.
        
        Args:
            prompt_file: Path to the JSONL file containing prompts
            output_dir: Directory to save Claude outputs (default: cc_outputs_<timestamp>)
        """
        if output_dir is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_dir = f"cc_outputs_{timestamp}"
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        self._logger.info(f"Created output directory: {output_dir}")
        
        if not os.path.exists(prompt_file):
            self._logger.fatal(f"Prompt file not found: {prompt_file}")
        
        with open(prompt_file, 'r') as f:
            for i, line in enumerate(f):
                line = line.strip()
                if not line:
                    continue
                
                try:
                    # Parse the prompt - could be raw text or JSON
                    try:
                        prompt_data = json.loads(line)
                        if isinstance(prompt_data, dict):
                            prompt = prompt_data.get('prompt', str(prompt_data))
                        else:
                            prompt = str(prompt_data)
                    except json.JSONDecodeError:
                        prompt = line
                    
                    self._logger.info(f"Processing prompt {i+1}: {prompt[:50]}...")
                    
                    # Create output file path
                    output_file = os.path.join(output_dir, f"response_{i+1:03d}.json")
                    
                    # Run claude command and capture output
                    try:
                        result = subprocess.run([
                            'claude', '-p', prompt, '-c', '--output-format', 'json'
                        ], capture_output=True, text=True, timeout=300)
                        
                        if result.returncode == 0:
                            # Save the output
                            with open(output_file, 'w') as out_f:
                                out_f.write(result.stdout)
                            
                            # Also save metadata
                            metadata_file = os.path.join(output_dir, f"response_{i+1:03d}_meta.json")
                            metadata = {
                                'prompt': prompt,
                                'prompt_number': i + 1,
                                'line_number': i + 1,
                                'timestamp': datetime.now().isoformat(),
                                'exit_code': result.returncode,
                                'stderr': result.stderr
                            }
                            with open(metadata_file, 'w') as meta_f:
                                json.dump(metadata, meta_f, indent=2)
                            
                            self._logger.info(f"Saved response to: {output_file}")
                        else:
                            self._logger.error(f"Claude command failed for prompt {i+1}: {result.stderr}")
                            # Save error info
                            error_file = os.path.join(output_dir, f"error_{i+1:03d}.txt")
                            with open(error_file, 'w') as err_f:
                                err_f.write(f"Exit code: {result.returncode}\n")
                                err_f.write(f"Stderr: {result.stderr}\n")
                                err_f.write(f"Prompt: {prompt}\n")
                    
                    except subprocess.TimeoutExpired:
                        self._logger.error(f"Timeout for prompt {i+1}")
                        timeout_file = os.path.join(output_dir, f"timeout_{i+1:03d}.txt")
                        with open(timeout_file, 'w') as timeout_f:
                            timeout_f.write(f"Timeout after 300 seconds\n")
                            timeout_f.write(f"Prompt: {prompt}\n")
                    
                    except Exception as e:
                        self._logger.error(f"Unexpected error for prompt {i+1}: {str(e)}")
                        error_file = os.path.join(output_dir, f"error_{i+1:03d}.txt")
                        with open(error_file, 'w') as err_f:
                            err_f.write(f"Error: {str(e)}\n")
                            err_f.write(f"Prompt: {prompt}\n")
                
                except Exception as e:
                    self._logger.error(f"Error processing line {i+1}: {str(e)}")
                    continue
        
        self._logger.info(f"Finished processing prompts. Results saved in: {output_dir}")
        
        # Create summary
        summary_file = os.path.join(output_dir, "summary.txt")
        with open(summary_file, 'w') as summary_f:
            summary_f.write(f"Claude CLI Batch Processing Summary\n")
            summary_f.write(f"===============================\n")
            summary_f.write(f"Prompt file: {prompt_file}\n")
            summary_f.write(f"Output directory: {output_dir}\n")
            summary_f.write(f"Timestamp: {datetime.now().isoformat()}\n")
            
            # Count files
            total_files = len([f for f in os.listdir(output_dir) if f.endswith('.json')])
            error_files = len([f for f in os.listdir(output_dir) if f.startswith('error')])
            timeout_files = len([f for f in os.listdir(output_dir) if f.startswith('timeout')])
            
            summary_f.write(f"Total responses: {total_files}\n")
            summary_f.write(f"Errors: {error_files}\n")
            summary_f.write(f"Timeouts: {timeout_files}\n")