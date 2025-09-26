# Docker Compose Update Tasks

This directory contains three Ansible tasks to manage docker-compose file updates:

## 1. update-compose.yaml
Task to copy static docker-compose files from the Ansible controller to the remote host.

### Required variables:
- `update_compose_remote_path`: Path to the docker-compose.yml file on the remote host
- `update_compose_local_path`: Path to the local docker-compose.yml file
- `update_compose_project_path`: Docker Compose project directory

### Optional variables:
- `force_update`: Force update even if files are identical (default: false)
- `max_backups`: Maximum number of backup files to keep (default: 3)
- `validate_compose`: Validate docker-compose syntax before deployment (default: true)
- `cleanup_resources`: Clean up unused Docker resources after deployment (default: true)

### Usage example:
```yaml
- include_tasks: tasks/docker/update-compose.yaml
  vars:
    update_compose_local_path: "{{ playbook_dir }}/templates/myapp/docker-compose.yml"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    force_update: false
```

## 2. update-compose-template.yaml
Task to render and deploy docker-compose templates using Ansible's template system.

### Required variables:
- `update_compose_remote_path`: Path to the docker-compose.yml file on the remote host
- `template_file_name`: Template file name (relative to templates/ directory)
- `update_compose_project_path`: Docker Compose project directory

### Optional variables:
- `force_update`: Force update even if contents are identical (default: false)
- `pull_retries`: Number of pull attempts (default: 5)
- `pull_delay`: Delay between attempts in seconds (default: 20)
- `max_backups`: Maximum number of backup files to keep (default: 3)
- `validate_compose`: Validate docker-compose syntax before deployment (default: true)
- `cleanup_resources`: Clean up unused Docker resources after deployment (default: true)

### Usage example:
```yaml
- include_tasks: tasks/docker/update-compose-template.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    pull_retries: 3
    pull_delay: 10
```

## 3. update-compose-unified.yaml
Unified task that supports both static file copying and template rendering.

### Required variables:
- `update_compose_remote_path`: Path to the docker-compose.yml file on the remote host
- `update_compose_project_path`: Docker Compose project directory
- One of these two:
  - `update_compose_local_path`: For copy mode
  - `template_file_name`: For template mode

### Optional variables:
- `force_update`: Force update (default: false)
- `pull_retries`: Number of pull attempts (default: 3)
- `pull_delay`: Delay between attempts in seconds (default: 10)
- `max_backups`: Maximum number of backup files to keep (default: 3)
- `validate_compose`: Validate docker-compose syntax before deployment (default: true)
- `cleanup_resources`: Clean up unused Docker resources after deployment (default: true)

### Usage example (copy mode):
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    update_compose_local_path: "{{ playbook_dir }}/files/myapp/docker-compose.yml"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
```

### Usage example (template mode):
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
```

## Implemented improvements

### Robustness:
- Validation of required variables at startup
- More granular error handling
- Retry logic for image pulling
- Automatic backup of existing files
- Local file existence checks

### Reduced redundancy:
- Common logic extracted into reusable blocks
- Unified task supporting both modes
- Clearer and consistent debug messages
- Variables with sensible default values

### Added features:
- **Smart backup management**: Keeps only the last N backups (configurable)
- **Pre-deployment validation**: Verifies docker-compose syntax before overwriting
- **Automatic cleanup**: Removes unused images, volumes and networks after deployment
- **Automatic backup of existing files** with timestamp
- **Configurable retry parameters**
- **More rigorous input validation**
- **Improved operation logging**

## New security and maintenance features

### Backup Management:
- Backups are automatically created by Ansible with format: `docker-compose.yml.timestamp~`
- Only the configured number of backups is kept (default: 3)
- Older backups are automatically removed

### Pre-Deployment Validation:
- Before overwriting the existing file, the syntax of the new docker-compose is validated using `docker compose config`
- If validation fails, the process stops without modifying the original file
- Uses a temporary file for validation that is always cleaned up
- Validation checks both YAML syntax and Docker Compose configuration

### Automatic Cleanup:
- After deploying the new containers, the following are removed:
  - Unused Docker images (including non-dangling ones)
  - Orphaned Docker volumes
  - Unused Docker networks
- Cleanup can be disabled with `cleanup_resources: false`
- Shows a report of removed resources

### Complete example with all options:
```yaml
- include_tasks: tasks/docker/update-compose-unified.yaml
  vars:
    template_file_name: "myapp/docker-compose.yml.j2"
    update_compose_remote_path: "/opt/myapp/docker-compose.yml"
    update_compose_project_path: "/opt/myapp"
    max_backups: 5                    # Keep 5 backups
    validate_compose: true            # Always validate (default)
    cleanup_resources: true           # Clean up after deployment (default)
    pull_retries: 5                   # 5 pull attempts
    pull_delay: 15                    # 15 seconds between attempts
    force_update: false               # Only if necessary
```

## Usage recommendations

1. **For simple projects**: Use `update-compose.yaml` for static files
2. **For projects with dynamic configurations**: Use `update-compose-template.yaml`
3. **For maximum flexibility**: Use `update-compose-unified.yaml`

All tasks are backward compatible with existing playbooks, but offer greater robustness and control over operations.
