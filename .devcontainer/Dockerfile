# Rename the base image's default non-root user (vscode, uid/gid 1000) to
# "jonathan", keeping the same uid/gid so workspace file ownership is unchanged.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG OLD_USER=vscode
ARG NEW_USER=jonathan

RUN set -eux; \
    # rename group, user, and home directory
    groupmod -n "$NEW_USER" "$OLD_USER"; \
    usermod -l "$NEW_USER" -d "/home/$NEW_USER" -m "$OLD_USER"; \
    # move the passwordless-sudo drop-in to match the new name
    if [ -f "/etc/sudoers.d/$OLD_USER" ]; then \
      mv "/etc/sudoers.d/$OLD_USER" "/etc/sudoers.d/$NEW_USER"; \
      sed -i "s/$OLD_USER/$NEW_USER/g" "/etc/sudoers.d/$NEW_USER"; \
    fi
