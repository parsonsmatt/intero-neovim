"""Tiny package configuration for testing purposes."""

from setuptools import find_packages, setup

setup(
    name='intero-neovim',
    version='0.0.1',
    packages=find_packages('.', exclude=['tests']),
)
