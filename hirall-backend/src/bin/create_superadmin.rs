use dotenvy::dotenv;
use hirall_backend::app::config::Config;
use hirall_backend::core::auth::{hash_password, verify_password};
use hirall_backend::core::database::create_pool;
use uuid::Uuid;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();
    println!("Connecting to Giftmart Supermarket DB on AWS RDS Aurora...");

    let config = Config::from_env();
    let shared_pool = create_pool(&config.database_url, 5).await?;
    let pool = shared_pool.read().await.clone();

    let email = "kipchirchirtoo01@gmail.com";
    let password = "Allan@13900";
    let name = "JOHNPAUL TOO";
    let role_name = "SUPERADMIN";

    println!("Looking up active organization...");
    let org_row = sqlx::query_as::<_, (Uuid, String)>(
        "SELECT id, name FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
    )
    .fetch_optional(&pool)
    .await?;

    let (org_id, org_name) = match org_row {
        Some(r) => r,
        None => {
            eprintln!("No active organization found!");
            return Ok(());
        }
    };

    println!("Organization: {} ({})", org_name, org_id);

    // 1. Hash password and PIN using Argon2
    println!("Hashing password using Argon2...");
    let password_hash = hash_password(password)?;
    let pin_hash = hash_password("1390")?;

    // 2. Insert or update user
    println!("Creating/Updating user {} ({}) ...", name, email);
    let user_row = sqlx::query_as::<_, (Uuid,)>(
        r#"
        INSERT INTO users (organization_id, name, email, password_hash, pin_code, status)
        VALUES ($1, $2, $3, $4, $5, 'ACTIVE')
        ON CONFLICT (organization_id, email) DO UPDATE SET
            name = EXCLUDED.name,
            password_hash = EXCLUDED.password_hash,
            pin_code = EXCLUDED.pin_code,
            status = 'ACTIVE',
            updated_at = NOW()
        RETURNING id
        "#,
    )
    .bind(org_id)
    .bind(name)
    .bind(email)
    .bind(&password_hash)
    .bind(&pin_hash)
    .fetch_one(&pool)
    .await?;

    let user_id = user_row.0;
    println!("User ID: {}", user_id);

    // 3. Ensure role exists (SUPERADMIN and OWNER)
    for r_name in &[role_name, "OWNER"] {
        let role_row = sqlx::query_as::<_, (Uuid,)>(
            r#"
            INSERT INTO roles (organization_id, name, description, is_system)
            VALUES ($1, $2, $3, true)
            ON CONFLICT (organization_id, name) DO UPDATE SET name = EXCLUDED.name
            RETURNING id
            "#,
        )
        .bind(org_id)
        .bind(r_name)
        .bind(format!("{} Role", r_name))
        .fetch_one(&pool)
        .await?;

        let role_id = role_row.0;

        // 4. Assign role in user_roles
        let _ = sqlx::query(
            r#"
            INSERT INTO user_roles (user_id, role_id, branch_id)
            VALUES ($1, $2, NULL)
            ON CONFLICT (user_id, role_id, branch_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(role_id)
        .execute(&pool)
        .await;

        println!("Assigned role {} ({}) to user", r_name, role_id);
    }

    // 5. Verify password hash
    let valid = verify_password(password, &password_hash)?;
    println!(
        "Password verification check: {}",
        if valid { "PASSED" } else { "FAILED" }
    );

    println!("\n========================================================");
    println!("Superadmin Account Successfully Configured!");
    println!("Organization: {}", org_name);
    println!("User Name:    {}", name);
    println!("Email:        {}", email);
    println!("Password:     {}", password);
    println!("Roles:        SUPERADMIN, OWNER (Enterprise-wide access)");
    println!("========================================================");

    Ok(())
}
