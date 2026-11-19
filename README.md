# Campus Lost & Found - Vercel (browser) version

DBMS capstone progress prototype. HTML, CSS and JavaScript only: no server and no environment variables needed.

- `schema.sql` - tables, foreign keys, indexes, a view, a trigger and the demo data
- `db.js` - loads `schema.sql` into an SQLite database running in the browser (sql.js) and runs every SQL query
- `app.js`, `index.html`, `style.css` - the student and staff dashboards

## Deploy on Vercel
1. Put these 6 files at the **root** of a GitHub repository (index.html must be at the top level, not inside a sub-folder).
2. On vercel.com choose Add New > Project, import the repository, leave every setting empty, click Deploy.
(Or drag-and-drop the folder contents into a new Vercel project.)

## Run locally
Open the folder in VS Code and use the Live Server extension, or run `npx serve` and open the link. Opening index.html directly from the file system will not work because the browser blocks loading schema.sql.

## Logins
| Tab | Email | Password |
|---|---|---|
| Student Login | jiya.gupta@campus.edu | Student@123 |
| Staff | sunita.rao@campus.edu | Admin@123 |

## Notes
- Data is stored in the browser (localStorage). Changes persist on the same browser and are not shared between devices. Staff > Reports has a "Reset demo data" button to restore the original data.
- Uses fictional demonstration data. Integration with the college's official student database and production infrastructure will be added later.
- The full Node.js + MySQL version of this project is provided separately.
