-- Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_type VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create jobs table if not exists
CREATE TABLE IF NOT EXISTS jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(100) NOT NULL,
    company VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(100) NOT NULL,
    deadline DATE NOT NULL,
    employer_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employer_id) REFERENCES users(id)
);

-- Create applications table if not exists
CREATE TABLE IF NOT EXISTS applications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    job_id INTEGER NOT NULL,
    job_seeker_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    cv_file VARCHAR(255),
    cover_letter TEXT,
    applied_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(id),
    FOREIGN KEY (job_seeker_id) REFERENCES users(id)
);

-- Create reviews table if not exists
CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    rating INTEGER NOT NULL,
    comment TEXT NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 



PRAGMA foreign_keys = ON;

-- Master table for companies (optional normalization of jobs.company)
CREATE TABLE IF NOT EXISTS companies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Job categories (e.g., Backend, Data, QA)
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Bridge: jobs ↔ categories (many-to-many)
CREATE TABLE IF NOT EXISTS job_categories (
    job_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (job_id, category_id),
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);


-- Views
CREATE VIEW IF NOT EXISTS v_job_details AS
SELECT
    j.id AS job_id,
    j.title,
    j.company,
    j.description,
    j.location,
    j.deadline,
    j.created_at,
    u.id AS employer_id,
    u.name AS employer_name,
    COALESCE((SELECT GROUP_CONCAT(c.name, ', ') FROM job_categories jc JOIN categories c ON c.id = jc.category_id WHERE jc.job_id = j.id), '') AS categories,
    '' AS skills
FROM jobs j
JOIN users u ON u.id = j.employer_id;

CREATE VIEW IF NOT EXISTS v_applications_extended AS
SELECT
    a.id AS application_id,
    a.status,
    a.applied_date,
    a.cv_file,
    a.cover_letter,
    js.id AS applicant_id,
    js.name AS applicant_name,
    js.email AS applicant_email,
    j.id AS job_id,
    j.title AS job_title,
    j.company AS job_company,
    emp.id AS employer_id,
    emp.name AS employer_name
FROM applications a
JOIN users js ON js.id = a.job_seeker_id
JOIN jobs j ON j.id = a.job_id
JOIN users emp ON emp.id = j.employer_id;

-- Indices
CREATE INDEX IF NOT EXISTS idx_jobs_employer_id ON jobs(employer_id);
CREATE INDEX IF NOT EXISTS idx_applications_job_id ON applications(job_id);
CREATE INDEX IF NOT EXISTS idx_applications_job_seeker_id ON applications(job_seeker_id);
CREATE INDEX IF NOT EXISTS idx_job_categories_job_id ON job_categories(job_id);
-- idx_job_skills_job_id removed (table not present)

-- Trigger to populate companies from jobs.company without breaking app
CREATE TRIGGER IF NOT EXISTS trg_jobs_insert_company
AFTER INSERT ON jobs
FOR EACH ROW
BEGIN
    INSERT OR IGNORE INTO companies(name) VALUES (NEW.company);
END;



-- Job seeker: search by category/date (skills removed for simplicity)

-- :categoryName, :afterDate

-- SELECT j.id, j.title, j.company, j.location, j.deadline
-- FROM jobs j
-- LEFT JOIN job_categories jc ON jc.job_id = j.id
-- LEFT JOIN categories c ON c.id = jc.category_id
-- WHERE (:categoryName IS NULL OR c.name = :categoryName)
--   AND (:afterDate IS NULL OR date(j.created_at) >= date(:afterDate))
-- GROUP BY j.id
-- ORDER BY j.created_at DESC;

