# -*- coding: utf-8 -*-

'''Unit tests for the intero.py module.'''

import pytest


@pytest.fixture
def mock_vim(mocker):
    mock = mocker.MagicMock()
    mocker.patch.dict('sys.modules', vim=mock)
    return mock


def test_stack_dirname(mock_vim):
    from intero import stack_dirname

    example_intero_stack_yaml = '/home/foobar/stack.yaml'
    mock_vim.configure_mock(**{'eval.return_value': example_intero_stack_yaml})
    assert stack_dirname() == '/home/foobar'


def test_strip_internal(mock_vim):
    from intero import strip_internal

    assert strip_internal('\x1b[38;2;255;100;0mλ> \x1b[m') == 'λ> '
    assert strip_internal('\x1b[01;31mfoobar') == 'foobar'
    assert strip_internal('\x1b[?2lfoobar') == 'foobar'
