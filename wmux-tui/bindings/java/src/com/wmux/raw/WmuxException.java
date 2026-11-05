package com.cmux.raw;

public class WmuxException extends Exception {
    private static final long serialVersionUID = 1L;

    public WmuxException(String message) {
        super(message);
    }

    public WmuxException(String message, Throwable cause) {
        super(message, cause);
    }
}
