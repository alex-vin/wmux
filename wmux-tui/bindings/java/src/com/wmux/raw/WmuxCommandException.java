package com.cmux.raw;

public final class WmuxCommandException extends WmuxException {
    private static final long serialVersionUID = 1L;
    private final String serverMessage;
    @SuppressWarnings("serial")
    private final Object commandId;
    private final String errorCode;
    private final WmuxErrorDelivery errorDelivery;

    public WmuxCommandException(String serverMessage, Object commandId) {
        this(serverMessage, commandId, null, null);
    }

    public WmuxCommandException(
        String serverMessage,
        Object commandId,
        WmuxErrorDelivery errorDelivery
    ) {
        this(serverMessage, commandId, null, errorDelivery);
    }

    public WmuxCommandException(
        String serverMessage,
        Object commandId,
        String errorCode,
        WmuxErrorDelivery errorDelivery
    ) {
        super(serverMessage);
        this.serverMessage = serverMessage;
        this.commandId = commandId;
        this.errorCode = errorCode;
        this.errorDelivery = errorDelivery;
    }

    public String serverMessage() {
        return serverMessage;
    }

    public Object commandId() {
        return commandId;
    }

    public String errorCode() {
        return errorCode;
    }

    public WmuxErrorDelivery errorDelivery() {
        return errorDelivery;
    }
}
