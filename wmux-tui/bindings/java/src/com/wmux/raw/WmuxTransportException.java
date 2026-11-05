package com.cmux.raw;

public final class WmuxTransportException extends WmuxException {
    private static final long serialVersionUID = 1L;

    public WmuxTransportException(String message, Throwable cause) {
        super(message, cause);
    }

    public WmuxTransportException(String message) {
        super(message);
    }
}
