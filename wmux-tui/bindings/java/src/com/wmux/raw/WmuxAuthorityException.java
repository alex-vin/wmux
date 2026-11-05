package com.cmux.raw;

/** The client was not configured for the authority required by a command. */
public final class WmuxAuthorityException extends WmuxException {
    private static final long serialVersionUID = 1L;

    public WmuxAuthorityException(String message) {
        super(message);
    }
}
