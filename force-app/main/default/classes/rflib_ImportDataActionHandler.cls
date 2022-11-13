public class rflib_ImportDataActionHandler implements rflib_RetryableActionHandler {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_ImportDataActionHandler');

    public void execute(List<rflib_Retryable_Action__e> actions) {
        LOGGER.info('Executing import action.');
        SampleDataController.importSampleData();
    }
}
