public class CheckNewContactsBatchScheduler implements Schedulable  {
public void execute(SchedulableContext sc) {
        CheckNewContactsBatch batchJob = new CheckNewContactsBatch(); 
        Integer batchSize = 200;
        Database.executeBatch(batchJob, batchSize);
    }
   public static void scheduleBatch(String jobName, String cronExpression) {
        CheckNewContactsBatchScheduler scheduler = new CheckNewContactsBatchScheduler();
        System.schedule(jobName, cronExpression, scheduler);
    }
}